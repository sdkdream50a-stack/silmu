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
  # AI 인용 시 법령 명칭이 함께 끌려가도록 GEO 권위자 4차 추천에 따라 명시
  def topic_law_label(topic)
    case topic.category
    when "travel", "duty", "salary" then "공무원 보수·복무규정"
    when "subsidy" then "보조금 관리법"
    when "property" then "공유재산 및 물품관리법"
    else
      topic.sector == "edu" ? "교육재정 관계법령" : "지방계약법·시행령"
    end
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
