xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "실무.kr — 공무원 계약·예산 실무 가이드"
    xml.description "공무원을 위한 계약·예산 실무 법령 가이드, 감사사례, 자동화 도구 최신 업데이트"
    xml.link root_url
    xml.language "ko"
    xml.copyright "© 2026 실무.kr"
    xml.tag! "atom:link", href: feed_url(format: :rss), rel: "self", type: "application/rss+xml"
    xml.lastBuildDate @updated_at&.rfc2822 || Time.current.rfc2822
    xml.image do
      xml.url "https://silmu.kr/og-image.png"
      xml.title "실무.kr"
      xml.link root_url
    end

    # 최신 토픽 (법령 가이드)
    @topics.each do |topic|
      xml.item do
        xml.title "#{topic.name} — 지방계약법 근거·절차·실무사례 완전정리"
        xml.link topic_url(topic.slug)
        xml.guid topic_url(topic.slug), isPermaLink: "true"
        xml.description do
          xml.cdata! topic.summary.to_s
        end
        xml.pubDate topic.updated_at.rfc2822
        xml.category "법령 가이드"
      end
    end

    # 최신 감사사례
    @audit_cases.each do |audit_case|
      xml.item do
        xml.title "#{audit_case.title} — 실제 감사 지적 사례와 대응 방법"
        xml.link audit_case_url(audit_case.slug)
        xml.guid audit_case_url(audit_case.slug), isPermaLink: "true"
        xml.description do
          xml.cdata! audit_case.summary.to_s
        end
        xml.pubDate audit_case.created_at.rfc2822
        xml.category "감사사례"
      end
    end
  end
end
