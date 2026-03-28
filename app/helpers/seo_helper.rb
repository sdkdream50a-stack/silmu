module SeoHelper
  def json_ld(data)
    content_tag(:script, json_escape(data.to_json).html_safe, type: "application/ld+json")
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
