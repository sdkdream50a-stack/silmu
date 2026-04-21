class LlmsController < ApplicationController
  TOPIC_LIMIT = 500
  AUDIT_LIMIT = 50

  def full
    expires_in 1.hour, public: true

    # Topic·AuditCase의 최신 updated_at을 키에 포함해 콘텐츠 갱신 시 자동 무효화
    cache_key = [
      "llms-full",
      "v1",
      Topic.published.maximum(:updated_at)&.to_i,
      AuditCase.published.maximum(:updated_at)&.to_i,
    ].join("/")

    content = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
      @topics = Topic.published.where(parent_id: nil).order(:category, :name).limit(TOPIC_LIMIT)
      @audit_cases = AuditCase.published.order(updated_at: :desc).limit(AUDIT_LIMIT)
      build_content
    end

    render plain: content, content_type: "text/plain; charset=utf-8"
  end

  private

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
