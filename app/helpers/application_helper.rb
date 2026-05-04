module ApplicationHelper
  ACTIVE_TOOL_COUNT = 37

  # exam.silmu.kr — 법령 가이드 slug → 한국어 레이블 맵
  # chapters/show.html.erb에서 related_topic_slugs 렌더링 시 사용
  TOPIC_SLUG_LABELS = {
    "public-procurement-overview"   => "공공조달 개요",
    "private-contract"              => "수의계약",
    "bidding"                       => "입찰 절차",
    "bid-qualification"             => "입찰참가자격",
    "e-procurement-guide"           => "전자조달(나라장터)",
    "e-bidding"                     => "전자입찰",
    "mas-contract"                  => "다수공급자계약(MAS)",
    "national-vs-local-contract-law" => "국가·지방계약법 비교",
    "bid-participation-restriction" => "입찰참가자격 제한",
    "estimated-price"               => "예정가격 산정",
    "dual-quote"                    => "2인 견적",
    "qualification-failure"         => "낙찰 실패 처리",
    "price-negotiation"             => "가격협상",
    "contract-guarantee-deposit"    => "계약보증금",
    "lowest-bid-rate"               => "낙찰하한율",
    "contract"                      => "계약 실무",
    "goods-vs-service-contract"     => "물품·용역 계약 구분",
    "goods-selection-committee"     => "물품선정위원회",
    "inspection"                    => "검수·검사",
    "late-penalty"                  => "지체상금",
    "payment"                       => "대금 지급",
    "design-change"                 => "설계변경",
    "contract-termination"          => "계약 해지·해제",
    "unit-price-contract"           => "단가계약",
    "subcontract"                   => "하도급",
    "price-escalation"              => "물가변동(ESC)",
    "defect-warranty"               => "하자보수",
    "budget"                        => "예산 편성",
    "expense"                       => "원가·비용 계산",
    "national-contract-act"         => "국가계약법",
    "contract-management"           => "계약이행 관리"
  }.freeze

  # slug → 한국어 레이블 반환 (없으면 slug 그대로)
  def topic_slug_label(slug)
    TOPIC_SLUG_LABELS[slug] || slug.gsub("-", " ")
  end

  def tool_count
    ACTIVE_TOOL_COUNT
  end

  # 도구별 "이런 상황에 사용" 1줄 안내 매핑
  # 권위자 패널 P1-2: 첫 입력란 위 사용 시점 안내문 (KWCAG·UX 보강)
  TOOL_USE_WHEN = {
    "allowance-calculator"            => "정근수당·가족수당·명절휴가비 등 수당 산정 시",
    "annual-leave-calculator"         => "연가일수 산정·잔여일수·소멸 확인 시",
    "audit-readiness-checker"         => "감사 대비 자체점검 항목 확인 시",
    "budget-category-finder"          => "지출 내용 → 예산과목(목·세목) 결정 시",
    "budget-estimator"                => "사업 예산편성 추정액 산출 시",
    "budget-execution-rate"           => "월·분기 예산집행률 점검·보고 시",
    "budget-transfer-checker"         => "예산 이용·전용 가능 여부 사전 검토 시",
    "contingency-fund"                => "예비비 한도(법정 1%) 적정성 확인 시",
    "contract-documents"              => "수의계약 사유서 등 계약 문서 자동 생성 시",
    "contract-guarantee"              => "계약보증금 면제·납부 산정 시",
    "contract-legality-check"         => "계약 체결 전 적법성 사전 점검 시",
    "contract-method"                 => "계약 방식(수의·경쟁·견적) 결정 시",
    "contract-reason"                 => "수의계약 사유서 hwpx 자동 생성 시",
    "cost-calculation"                => "원가계산서 검토·재무평가 시",
    "cost-estimate"                   => "원가계산서 자동 생성 시",
    "design-change"                   => "설계변경 신청서·승인서 작성 시",
    "estimated-price"                 => "예정가격 작성·적정성 검토 시",
    "insurance-calculator"            => "건강보험·국민연금 등 4대보험료 산정 시",
    "legal-period"                    => "법정 기한·민원 처리기간 산정 시",
    "official-document"               => "공문(수신자·시행문) 자동 생성 시",
    "overtime-calculator"             => "시간외근무수당(월 한도 포함) 산정 시",
    "pdf"                             => "PDF 분할·병합·페이지번호·정보 확인 시",
    "pension-calculator"              => "공무원연금 예상 수령액 시뮬레이션 시",
    "performance-bonus-calculator"    => "성과상여금 등급별(S·A·B·C) 산정 시",
    "price-adjustment-calculator"     => "물가변동 ESC 조정(지수·품목조정률) 시",
    "progress-inspection"             => "기성검사·완료검사 조서 작성 시",
    "project-plan"                    => "사업계획서 hwpx 자동 생성 시",
    "qualification-evaluation"        => "적격심사·낙찰자 결정 점수 검토 시",
    "quote-auto"                      => "견적서 자동 추출·정리 시",
    "quote-review"                    => "견적서 적정성·재무평가 즉시 검토 시",
    "salary-calculator"               => "공무원 봉급(월급) 본봉 산정 시",
    "severance-calculator"            => "퇴직수당·퇴직금 산정 시",
    "split-contract-checker"          => "분할계약 위반 여부 사전 검토 시",
    "standard-term-checker"           => "기안서·사유서 작성 후 행정 표준어 준수 여부 확인 시",
    "subsidy-settlement-checker"      => "보조금 정산 제출 전 자가점검 시",
    "task-calendar"                   => "월별 업무 일정·법정 기한 관리 시",
    "travel-calculator"               => "공무원 여비(국내/국외 출장) 산정 시"
  }.freeze

  def tool_use_when(slug)
    return nil if slug.blank?
    TOOL_USE_WHEN[slug.to_s]
  end

  # E-E-A-T 검증 타임스탬프 (Sprint A — gimi9 "기미 버전" 벤치마킹)
  # Topic: law_verified_at 우선, 없으면 updated_at
  # AuditCase: updated_at (별도 verified_at 필드 없음)
  def silmu_verification_date(record)
    return record.law_verified_at.presence || record.updated_at if record.respond_to?(:law_verified_at)
    record.try(:updated_at)
  end

  def utm_params
    session[:utm_params] || {}
  end

  def utm_source
    utm_params[:utm_source] || utm_params["utm_source"]
  end

  def from_naver_blog?
    utm_source == "naver_blog"
  end

  # 현재 페이지에 해당하는 네비게이션 메뉴에 활성 클래스 반환
  def nav_class(section)
    active = case section
    when :guides       then request.path.start_with?("/guides") && !request.path.start_with?("/guides/resources")
    when :topics       then request.path.start_with?("/topics")
    when :audit_cases  then request.path.start_with?("/audit-cases")
    when :tools        then request.path.start_with?("/tools") && !request.path.start_with?("/tools/task-calendar")
    when :task_calendar then request.path.start_with?("/tools/task-calendar")
    when :resources    then request.path.start_with?("/guides/resources")
    when :feedback     then request.path.start_with?("/feedback")
    end
    active ? "nav-link py-2 nav-link-active" : "nav-link py-2"
  end

  # 법령 콘텐츠를 HTML로 변환 (간단한 Markdown 변환)
  # 조, 항, 호 기준으로 줄바꿈하고 가시성 향상
  # 결과를 캐싱하여 무거운 정규식 처리를 반복하지 않음
  def render_legal_content(content)
    return "" if content.blank?

    # v2: LegalContentRenderer 헤딩 체계 변경(h4→h3, WCAG 1.3.1 수정)으로 캐시 무효화
    cache_key = "legal_content/v2/#{Digest::MD5.hexdigest(content)}"
    cached = Rails.cache.read(cache_key)
    return cached.html_safe if cached

    result = LegalContentRenderer.render(content)
    Rails.cache.write(cache_key, result, expires_in: 24.hours)
    result.html_safe
  end

  # 페이지 타입별 OG 이미지 URL 반환
  # 컨트롤러에서 set_og_image(category:)로 @og_image_path가 설정되면 해당 이미지 사용
  # 없으면 기본 이미지 사용
  def og_image_url_for_page
    @og_image_path.presence || "https://silmu.kr/og-image.webp"
  end

  # 간단한 Markdown 변환 (일반 콘텐츠용)
  def simple_markdown(content)
    return "" if content.blank?

    html = sanitize(content, tags: [], attributes: []).dup

    # 제목
    html = html.gsub(/^### (.+)$/, '<h4>\1</h4>')
    html = html.gsub(/^## (.+)$/, '<h3>\1</h3>')

    # 강조
    html = html.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')

    # 목록
    html = html.gsub(/^[-*]\s+(.+)$/, '<li>\1</li>')
    html = html.gsub(/(<li>.*?<\/li>\n?)+/) { |match| "<ul>#{match}</ul>" }

    # 줄바꿈
    html = html.gsub(/\n\n+/, "</p><p>")
    html = html.gsub(/\n/, "<br>")

    "<p>#{html}</p>".html_safe
  end
end
