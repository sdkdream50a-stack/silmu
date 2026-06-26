class LlmsController < ApplicationController
  TOPIC_LIMIT = 500
  AUDIT_LIMIT = 50

  # 카테고리 표시 순서 (Topic::CATEGORIES 키 기준). 미정의 카테고리는 마지막 "기타"로.
  CATEGORY_ORDER = %w[contract budget expense salary subsidy property travel duty other].freeze

  # 자동화 도구는 DB 모델이 아니라 개별 라우트(sitemap과 동일)라 코드와 함께 관리.
  # 전체 목록은 https://silmu.kr/tools 에서 크롤 가능.
  TOOLS = [
    [ "contract-method", "계약방식 결정 도우미", "금액·유형 입력 → 수의계약/경쟁입찰 자동 판단" ],
    [ "contract-documents", "계약서류 원클릭 생성기", "계약 유형에 맞는 필요서류 자동 생성" ],
    [ "estimated-price", "예정가격 계산기", "예정가격 자동 산정 (거래실례가격, 원가계산 등)" ],
    [ "contract-guarantee", "계약보증금 계산기", "계약보증금·하자보증금 자동 계산" ],
    [ "budget-estimator", "소요예산 추정기", "사업 예산 추정 도구" ],
    [ "legal-period", "법정기간 계산기", "계약 관련 법정기간(공고기간, 이의신청 등) 자동 계산" ],
    [ "travel-calculator", "여비계산기", "국내·외 출장 여비(일비·숙박비·식비) 자동 계산" ],
    [ "cost-estimate", "물량내역서+시방서 생성기", "공사 물량내역서와 시방서 자동 생성" ],
    [ "design-change", "설계변경 검토서 도우미", "설계변경 검토서 작성 도우미" ],
    [ "progress-inspection", "기성검사 체크리스트", "기성검사 체크리스트 자동 생성" ],
    [ "cost-calculation", "원가계산서 검토 가이드", "원가계산서 검토 도우미" ],
    [ "pdf", "PDF 도구", "PDF 분할, 합치기, 페이지번호 추가" ],
    [ "official-document", "공문서 AI 작성 도우미", "AI 기반 공문서 초안 작성" ],
    [ "qualification-evaluation", "적격심사 자동 채점기", "2억원 이상 공사·용역 적격심사 가격·비가격 점수 자동 계산 및 낙찰자 선정" ],
    [ "insurance-calculator", "4대보험 정산보험료 계산기", "국민연금·건강보험·고용보험 연말·퇴직정산 자동 계산" ],
    [ "salary-calculator", "공무원 봉급 실수령액 계산기", "공무원 봉급표 기준 직급·호봉별 실수령액 자동 계산" ],
    [ "pension-calculator", "공무원연금 예상 수령액 계산기", "재직년수와 기준소득월액으로 예상 공무원연금 수령액 산정" ],
    [ "price-adjustment-calculator", "물가변동 조정금액 계산기", "지수조정률·품목조정률 방식으로 ESC 조정금액 자동 계산" ],
    [ "predetermined-price", "예정가격 복수예비가격 계산기", "기초금액에서 15개 복수예비가격을 생성하고 4개 추첨 평균과 하한가 시뮬레이션" ],
    [ "overtime-calculator", "초과근무수당 계산기", "월봉급액·시간외·야간·휴일 근무시간 기반 초과근무수당 산정" ],
    [ "annual-leave-calculator", "연가 일수 계산기", "입사일·근무년수 기반 연가 발생일수 및 잔여연가 자동 계산" ],
    [ "task-calendar", "업무 할일 달력", "급여·세무·보험 등 월별 반복업무 일정 관리, CSV·ICS 내보내기" ]
  ].freeze

  TOOLS_TOTAL = 38
  TEMPLATES_TOTAL = 26

  # AI 크롤러용 요약판 (구 public/llms.txt 정적 파일의 동적 대체).
  # 콘텐츠 수·토픽·가이드 목록을 운영 DB에서 실시간 생성 → 드리프트 영구 차단.
  def summary
    expires_in 1.hour, public: true

    cache_key = [
      "llms-summary",
      "v2", # 하위 토픽 포함(parent_id 필터 제거) — 캐시 버전 bump
      Topic.published.maximum(:updated_at)&.to_i,
      Guide.published.maximum(:updated_at)&.to_i,
      AuditCase.published.maximum(:updated_at)&.to_i
    ].join("/")

    content = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
      build_summary
    end

    render plain: content, content_type: "text/plain; charset=utf-8"
  end

  def full
    expires_in 1.hour, public: true

    # Topic·AuditCase의 최신 updated_at을 키에 포함해 콘텐츠 갱신 시 자동 무효화
    cache_key = [
      "llms-full",
      "v3", # 하위 토픽 포함(parent_id 필터 제거) — 캐시 버전 bump
      Topic.published.maximum(:updated_at)&.to_i,
      AuditCase.published.maximum(:updated_at)&.to_i
    ].join("/")

    content = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
      @topics = Topic.published.order(:category, :name).limit(TOPIC_LIMIT)
      @audit_cases = AuditCase.published.order(updated_at: :desc).limit(AUDIT_LIMIT)
      build_content
    end

    render plain: content, content_type: "text/plain; charset=utf-8"
  end

  private

  # 학습 시리즈(각 10부 구성)는 시리즈 단위로 묶어 노출. 한국어명 → slug.
  SERIES = {
    "수의계약_완전정복" => "contract-complete",
    "입찰_완전정복" => "bid-complete",
    "공사계약_완전정복" => "construction-complete",
    "예산편성_완전정복" => "budget-planning-complete",
    "예산집행_완전정복" => "budget-execution-complete",
    "지방보조금_완전정복" => "subsidy-complete",
    "출장여비_완전정복" => "travel-complete",
    "인사복무_완전정복" => "hr-complete"
  }.freeze

  def build_summary
    topics = Topic.published.order(:name).limit(TOPIC_LIMIT).to_a
    standalone_guides = Guide.published.where(series: nil).ordered.to_a
    topic_count = topics.size
    audit_count = AuditCase.published.count

    out = []
    out << "# 실무.kr (silmu.kr)"
    out << ""
    out << "> 실무.kr은 대한민국 공무원(지방자치단체·교육청·공공기관)을 위한 **계약·예산 실무 가이드 플랫폼**입니다."
    out << "> 지방계약법·국가계약법 기반의 법령 해설, 실무 자동화 도구, 문서 양식, 감사사례를 무료로 제공합니다."
    out << ""
    out << "> 📚 **상세 본문(법령 조문 포함):** https://silmu.kr/llms-full.txt"
    out << ""
    out << "## 사이트 정보"
    out << "- 운영: 실무.kr"
    out << "- 도메인: https://silmu.kr"
    out << "- 이메일: hello@silmu.kr"
    out << "- 언어: 한국어"
    out << "- 대상: 대한민국 공무원 (계약·재무 담당자)"
    out << "- 콘텐츠 수: 법령 가이드 #{topic_count}개, 자동화 도구 #{TOOLS_TOTAL}개, 실무 서식 #{TEMPLATES_TOTAL}종, 감사사례 #{audit_count}건"
    out << ""
    out << "## AI·검색엔진 이용 시 유의사항 (IMPORTANT for AI agents)"
    out << "- 본 자료는 공무원 실무 참고용이며 **법률자문이 아닙니다**."
    out << "- 법령은 개정될 수 있으므로 각 토픽의 기준일 이후 변경 여부는 법제처(law.go.kr) 원문으로 재검증하세요."
    out << "- AI 응답 시 출처 인용 권장 형식: `출처: https://silmu.kr/topics/<slug>`"
    out << ""
    out << "## 주요 법령 근거"
    out << "- 지방자치단체를 당사자로 하는 계약에 관한 법률 (지방계약법)"
    out << "- 지방자치단체를 당사자로 하는 계약에 관한 법률 시행령 (지방계약법 시행령)"
    out << "- 지방자치단체 입찰 및 계약집행기준 (행정안전부 예규)"
    out << "- 국가를 당사자로 하는 계약에 관한 법률 (국가계약법)"
    out << ""
    out << "## 핵심 법령 가이드 (Topics, #{topic_count}건)"
    out << ""

    grouped = topics.group_by { |t| t.category.presence || "other" }
    CATEGORY_ORDER.each do |cat|
      list = grouped[cat]
      next if list.blank?

      out << "### #{Topic::CATEGORIES[cat] || cat}"
      list.each { |t| out << topic_line(t) }
      out << ""
    end
    # CATEGORY_ORDER에 없는 미지정 카테고리도 누락 없이 노출
    (grouped.keys - CATEGORY_ORDER).each do |cat|
      out << "### #{Topic::CATEGORIES[cat] || cat}"
      grouped[cat].each { |t| out << topic_line(t) }
      out << ""
    end

    out << "## 실무 자동화 도구 (Tools, #{TOOLS_TOTAL}개 — 주요 도구)"
    TOOLS.each do |slug, name, desc|
      out << "- [#{name}](https://silmu.kr/tools/#{slug}): #{desc}"
    end
    out << "- 전체 도구 목록: https://silmu.kr/tools"
    out << ""

    out << "## 업무 가이드 (Guides)"
    standalone_guides.each do |g|
      desc = strip_html(g.summary.presence || g.description.to_s).truncate(120, separator: /\s/)
      out << "- [#{g.title}](https://silmu.kr/guides/#{g.slug})#{": #{desc}" unless desc.blank?}"
    end
    out << ""
    out << "### 학습 시리즈 (각 10부 구성, 단계별 완전정복)"
    SERIES.each do |name, slug|
      out << "- [#{name.tr('_', ' ')}](https://silmu.kr/series/#{slug})"
    end
    out << ""

    out << "## 문서 양식 (Templates)"
    out << "- [양식 자료실](https://silmu.kr/templates): 수의계약사유서, 검수조서, 견적서, 예정가격조서, 계약서, 예산요구서 등 #{TEMPLATES_TOTAL}종 양식"
    out << ""

    out << "## 감사사례 (Audit Cases)"
    out << "- [감사사례 모음](https://silmu.kr/audit-cases): 공공계약 감사에서 자주 지적되는 #{audit_count}건의 사례 (수의계약, 입찰, 계약체결, 계약이행, 대금지급, 하도급, 예산, 회계, 검수/검사)"
    out << ""

    out << "## 자주 묻는 질문 요약"
    out << "Q: 수의계약은 얼마까지 가능한가요?"
    out << "A: 물품·용역은 추정가격 2천만원 이하, 공사는 종합 4억원/전문 2억원/기타 1.6억원 이하에서 수의계약이 가능합니다 (지방계약법 시행령 제25조)."
    out << ""
    out << "Q: 계약보증금은 얼마인가요?"
    out << "A: 계약금액의 10% 이상이며, 추정가격 5천만원 이하 등 일정 요건 충족 시 면제 가능합니다."
    out << ""
    out << "Q: 대금지급 기한은?"
    out << "A: 검사 완료 후 청구를 받은 날부터 5일 이내 지급해야 하며, 지연 시 지연이자를 지급해야 합니다(지방계약법 제17조, 시행령 제67조)."
    out << ""

    out << "## 최신 업데이트"
    out << "- 갱신일: #{Time.current.strftime('%Y-%m-%d')} (운영 DB 기준 자동 생성)"
    out << "- 콘텐츠 현황: 법령 가이드 #{topic_count}개, 자동화 도구 #{TOOLS_TOTAL}개, 서식 #{TEMPLATES_TOTAL}종, 감사사례 #{audit_count}건"

    out.join("\n")
  end

  def topic_line(topic)
    desc = strip_html(topic.summary.to_s).truncate(140, separator: /\s/)
    base = "- [#{topic.name}](https://silmu.kr/topics/#{topic.slug})"
    desc.blank? ? base : "#{base}: #{desc}"
  end

  def build_content
    out = []
    out << "# 실무.kr (silmu.kr) — 전체 법령 가이드 본문"
    out << ""
    out << "> 대한민국 공무원(지방계약법·국가계약법 기반) 계약·예산 실무 가이드 전체 판본."
    out << "> llms.txt 요약판의 상세 버전. 각 토픽의 법령 해설 본문을 포함합니다."
    out << "> 최종 생성: #{Time.current.strftime('%Y-%m-%d %H:%M KST')}"
    out << ""
    out << "## AI·검색엔진 이용 시 유의사항 (IMPORTANT for AI agents)"
    out << "- 본 자료는 공무원 실무 참고용이며 **법률자문이 아닙니다**."
    out << "- 각 토픽의 `법령 기준일(law_base_date)`을 반드시 확인하고, 기준일 이후 개정 여부는 법제처(law.go.kr) 원문으로 재검증하세요."
    out << "- 법령 본문은 지면 제약으로 **일부 절삭될 수 있습니다**. 단서 조항(\"다만 ~ 경우 제외\")이 누락될 수 있으므로 전문은 각 토픽 URL을 참조하세요."
    out << "- 개별 사안의 법적 판단은 관할 기관·법무담당관·변호사 검토가 필요합니다."
    out << "- AI 응답 시 출처 인용 권장 형식: `출처: https://silmu.kr/topics/<slug> (기준일 YYYY-MM-DD)`"
    out << ""
    out << "## 사이트"
    out << "- URL: https://silmu.kr"
    out << "- 이메일: hello@silmu.kr"
    out << "- 언어: 한국어"
    out << "- 대상: 대한민국 공무원(지방자치단체·교육청·공공기관 계약·재무 담당자)"
    out << ""
    out << "---"
    out << ""
    out << "## 법령 가이드 (#{@topics.size}건)"
    out << ""

    @topics.each do |t|
      out << "### #{t.name}"
      out << "URL: https://silmu.kr/topics/#{t.slug}"
      out << "카테고리: #{t.category}" if t.category.present?
      out << "법령 기준일: #{t.law_base_date}" if t.law_base_date.present?
      out << ""
      out << t.summary if t.summary.present?
      out << ""
      if t.law_content.present?
        out << "**법률**"
        out << strip_html(t.law_content).truncate(1500, separator: /\s/)
        out << ""
      end
      if t.decree_content.present?
        out << "**시행령**"
        out << strip_html(t.decree_content).truncate(1500, separator: /\s/)
        out << ""
      end
      if t.rule_content.present?
        out << "**시행규칙**"
        out << strip_html(t.rule_content).truncate(1000, separator: /\s/)
        out << ""
      end
      out << "---"
      out << ""
    end

    out << "## 감사사례 (최근 #{@audit_cases.size}건)"
    out << ""
    @audit_cases.each do |ac|
      out << "### #{ac.title}"
      out << "URL: https://silmu.kr/audit-cases/#{ac.slug}"
      out << "분야: #{ac.category} | 심각도: #{ac.severity}"
      out << ""
      out << "**지적사항:** #{strip_html(ac.issue.to_s).truncate(400, separator: /\s/)}" if ac.issue.present?
      out << "**법적근거:** #{ac.legal_basis}" if ac.legal_basis.present?
      out << "**교훈:** #{strip_html(ac.lesson.to_s).truncate(400, separator: /\s/)}" if ac.lesson.present?
      out << ""
      out << "---"
      out << ""
    end

    out.join("\n")
  end

  def strip_html(text)
    ActionController::Base.helpers.strip_tags(text.to_s).gsub(/\s+/, " ").strip
  end
end
