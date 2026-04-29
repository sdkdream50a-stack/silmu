module SeoHelper
  def json_ld(data)
    content_tag(:script, json_escape(data.to_json).html_safe, type: "application/ld+json")
  end

  # 토픽 howto_steps 배열을 schema.org HowToStep 배열로 변환
  def topic_howto_steps(steps)
    Array(steps).each_with_index.map do |s, i|
      h = {
        "@type" => "HowToStep",
        "position" => i + 1,
        "name" => s["name"].to_s,
        "text" => s["text"].to_s
      }
      h["url"] = s["url"] if s["url"].present?
      h
    end
  end

  # 토픽 1차 출처 — Article schema의 isBasedOn에 주입할 법령 Legislation 배열
  # (모든 토픽 공통 근거: 지방계약법 + 시행령 + 행안부 예규)
  def topic_legal_basis
    [
      { "@type" => "Legislation", "name" => "지방자치단체를 당사자로 하는 계약에 관한 법률",
        "url" => "https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률" },
      { "@type" => "Legislation", "name" => "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
        "url" => "https://www.law.go.kr/법령/지방자치단체를당사자로하는계약에관한법률시행령" },
      { "@type" => "Legislation", "name" => "지방자치단체 입찰 및 계약집행기준",
        "url" => "https://www.law.go.kr/행정규칙/지방자치단체입찰및계약집행기준" }
    ]
  end

  # 토픽 카테고리 → 1차 법령 표시 라벨 (Quick Answer 박스 chip + speakable .legal-citation)
  # 6차 권위자 #P1 — sector=edu 내부 [school / edu_office] 3-tier 분기 (전문가 패널 9:1 추천)
  # 법제처 OpenAPI 검증 완료 (2026-04-29) — 모든 법령 정식명 확인
  # 환각 제거: "교육공무원수당규정"·"학교회계법"·"교육기관 계약사무 처리지침" (존재X)
  # ⚠️ 학교 행정실의 행정직 공무원은 "지방공무원" (교육공무원 X) — label 작성 시 혼동 금지
  def topic_law_label(topic)
    if topic.sector == "edu" && topic.org_edu_office?
      # 시도교육청 본청·지원청 (지방공무원·일반행정직)
      case topic.category
      when "salary", "travel" then "공무원수당 등에 관한 규정·지방공무원법"
      when "duty" then "지방공무원법·지방교육자치에 관한 법률"
      when "budget" then "지방교육자치에 관한 법률·지방자치단체 교육비특별회계 예산편성 운용에 관한 규칙"
      when "expense" then "지방재정법·지방회계법·지방교육자치에 관한 법률"
      when "contract" then "지방계약법·시행령"
      else "지방교육자치에 관한 법률·교육재정 관계법령"
      end
    elsif topic.sector == "edu" # 단위학교 (school 또는 미분류 edu)
      # 단위학교 행정실 (교육공무원·교사 + 학교 행정실 지방공무원 혼재)
      case topic.category
      when "salary", "travel" then "공무원수당 등에 관한 규정·교육공무원법"
      when "duty" then "교육공무원법·국가공무원법"
      when "budget" then "초ㆍ중등교육법·지방교육재정교부금법"
      when "expense" then "초ㆍ중등교육법·시ㆍ도교육청 학교회계 규칙"
      when "contract" then "지방계약법·시행령"
      else "초ㆍ중등교육법·교육공무원법"
      end
    else
      case topic.category
      when "travel", "duty", "salary" then "공무원수당 등에 관한 규정·공무원보수규정"
      when "subsidy" then "보조금 관리에 관한 법률"
      when "property" then "공유재산 및 물품 관리법"
      when "budget" then "지방재정법·지방회계법"
      else "지방계약법·시행령"
      end
    end
  end

  # 6차 권위자 #P0-2.5 — 동적 headline (sector/category 분기, hardcoded 환각 제거)
  # 기존: "{name} — 지방계약법 근거·절차·실무사례 완전정리" (edu/salary 등에 부적합)
  def topic_headline(topic)
    label = topic_law_label(topic)
    suffix =
      case topic.category
      when "salary", "travel", "duty" then "근거·산정·실무사례"
      when "budget", "expense" then "근거·편성·실무사례"
      when "subsidy" then "근거·집행·실무사례"
      when "property" then "근거·관리·실무사례"
      else "근거·절차·실무사례"
      end
    "#{topic.name} — #{label} #{suffix}"
  end

  # 6차 권위자 #F1 — reviewedBy Organization 객체화
  # parentOrganization으로 실무.kr 조직과 연결 → E-E-A-T 강신호
  def topic_reviewed_by
    {
      "@type" => "Organization",
      "name" => "실무.kr 법령검증팀",
      "url" => "https://silmu.kr/about",
      "parentOrganization" => {
        "@type" => "Organization",
        "@id" => "https://silmu.kr/#org",
        "name" => "실무.kr",
        "url" => "https://silmu.kr"
      }
    }
  end

  # 6차 권위자 #F2 + P1 — sector·org_type 3-tier audience 분기
  # edu/school: 단위학교 행정실 / edu/edu_office: 시도교육청 본청·지원청
  def topic_audience(topic)
    if topic.sector == "edu" && topic.org_edu_office?
      {
        "@type" => "Audience",
        "audienceType" => "시·도교육청 행정직 공무원",
        "educationalRole" => "educationOfficeStaff",
        "geographicArea" => { "@type" => "Country", "name" => "대한민국" }
      }
    elsif topic.sector == "edu"
      {
        "@type" => "EducationalAudience",
        "audienceType" => "단위학교 행정실무자·교육공무원",
        "educationalRole" => "schoolAdministrator",
        "geographicArea" => { "@type" => "Country", "name" => "대한민국" }
      }
    elsif topic.sector == "local_gov"
      {
        "@type" => "Audience",
        "audienceType" => "지방자치단체 계약·재무 담당자",
        "geographicArea" => { "@type" => "Country", "name" => "대한민국" }
      }
    else
      {
        "@type" => "Audience",
        "audienceType" => "공무원·공공기관 계약·재무 담당자",
        "geographicArea" => { "@type" => "Country", "name" => "대한민국" }
      }
    end
  end

  # 6차 권위자 #H1 — sector=edu 토픽은 GovernmentService 다중타입 추가
  # AGO(정부 검색 신호) 강화 — 교육행정 서비스로 명시
  def topic_article_types(topic)
    types = [ "Article", "LearningResource" ]
    types << "GovernmentService" if topic.sector == "edu"
    types
  end

  # 6차 권위자 #H1 + P1 — edu 토픽 GovernmentService 분기
  # school: 단위학교 (provider=EducationalOrganization)
  # edu_office: 시도교육청 (provider=GovernmentOrganization)
  # 비-edu는 nil 반환 (호출 측에서 .compact로 제거)
  def topic_government_service_fields(topic)
    return nil unless topic.sector == "edu"

    if topic.org_edu_office?
      provider = {
        "@type" => "GovernmentOrganization",
        "name" => "시·도교육청 (본청·교육지원청)",
        "url" => "https://www.moe.go.kr"
      }
      service_type =
        case topic.category
        when "salary" then "교육행정직 공무원 수당 산정 안내"
        when "travel" then "교육행정직 공무원 여비 산정 안내"
        when "duty" then "교육행정직 공무원 복무 안내"
        when "budget" then "시·도교육청 교육비특별회계 편성 안내"
        when "expense" then "시·도교육청 지출·회계 안내"
        when "contract" then "시·도교육청 계약사무 안내"
        else "교육청 행정 실무 안내"
        end
    else # school 또는 미분류 edu
      provider = {
        "@type" => "EducationalOrganization",
        "name" => "단위학교 (행정실)",
        "url" => "https://www.moe.go.kr"
      }
      service_type =
        case topic.category
        when "salary" then "단위학교 수당 산정 안내"
        when "travel" then "단위학교 여비 산정 안내"
        when "duty" then "교육공무원·학교 행정실 복무 안내"
        when "budget" then "학교회계 예산편성 안내"
        when "expense" then "학교회계 지출 안내"
        when "contract" then "단위학교 계약사무 안내"
        else "단위학교 행정 실무 안내"
        end
    end

    {
      "provider" => provider,
      "serviceType" => service_type,
      "areaServed" => { "@type" => "Country", "name" => "대한민국" }
    }
  end

  # 토픽 wordCount — Article schema 정량 신호 (5차 권위자 GEO+AEO)
  # law_content/decree_content/rule_content/commentary plain text 길이 합산
  def topic_word_count(topic)
    sources = [ topic.summary, topic.law_content, topic.decree_content, topic.rule_content, topic.commentary ].compact
    text = sources.map { |s| ActionController::Base.helpers.strip_tags(s.to_s) }.join(" ")
    # 한국어 기준 — 어절(공백) 단위가 아닌 문자 단위 (LearningResource 신호용)
    text.gsub(/\s+/, "").length
  end

  # 토픽 timeRequired — ISO 8601 duration ("PT5M") (5차 권위자 LearningResource)
  # 한국어 평균 읽기 속도 ~300자/분 가정, 최소 1분
  def topic_reading_time_iso(topic)
    minutes = [ (topic_word_count(topic) / 300.0).ceil, 1 ].max
    "PT#{minutes}M"
  end

  # 도구 페이지용 WebApplication 구조화 데이터
  def tool_json_ld(tool_name:, description:, url:)
    {
      "@context" => "https://schema.org",
      "@type" => "WebApplication",
      "name" => tool_name,
      "description" => description,
      "url" => url,
      "applicationCategory" => "BusinessApplication",
      "operatingSystem" => "Web",
      "offers" => {
        "@type" => "Offer",
        "price" => "0",
        "priceCurrency" => "KRW"
      },
      "provider" => {
        "@type" => "Organization",
        "name" => "실무",
        "url" => "https://silmu.kr"
      }
    }
  end
end
