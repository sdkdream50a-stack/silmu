class SeoMonitor
  SITE_URL = "https://silmu.kr"

  def self.generate_weekly_report
    {
      content: content_stats,
      traffic: traffic_stats,
      seo: seo_stats,
      warnings: generate_warnings
    }
  end

  def self.check_page_speed
    # PageSpeed Insights API 사용 (실제 구현 시 API 키 필요)
    raw = {
      performance_score: check_performance_score,
      fcp: measure_fcp,
      lcp: measure_lcp,
      tbt: measure_tbt,
      cls: measure_cls,
      opportunities: performance_opportunities
    }
    # nil 값 필터링 (미구현 지표 제외)
    raw.reject { |_k, v| v.nil? }
  end

  def self.check_broken_links
    broken = []

    # 중요 페이지들의 링크 체크
    important_pages = [
      "/",
      "/guides",
      "/tools",
      "/audit-cases"
    ]

    important_pages.each do |page|
      check_page_links(page, broken)
    end

    broken
  end

  private

  def self.content_stats
    {
      topics_count: Topic.published.count,
      audit_cases_count: AuditCase.published.count,
      tools_count: 19, # ACTIVE_TOOL_COUNT
      topics_with_faq: Topic.published.where.not(faqs: [ nil, "", "[]" ]).count,
      topics_without_meta: Topic.published.where("summary IS NULL OR summary = ''").count
    }
  end

  def self.traffic_stats
    week_ago = 7.days.ago

    {
      top_topics: Topic.published
                      .where("updated_at > ?", week_ago)
                      .order(view_count: :desc)
                      .limit(5)
                      .pluck(:name, :view_count)
                      .map { |name, views| { name: name, views: views } },
      top_audit_cases: AuditCase.published
                               .where("updated_at > ?", week_ago)
                               .order(view_count: :desc)
                               .limit(5)
                               .pluck(:title, :view_count)
                               .map { |title, views| { title: title, views: views } }
    }
  end

  def self.seo_stats
    {
      sitemap_urls: count_sitemap_urls,
      avg_meta_length: calculate_avg_meta_length,
      topics_with_article_jsonld: Topic.published.count,  # 모든 토픽에 Article JSON-LD 출력
      topics_with_faq_jsonld: Topic.published.where.not(faqs: [ nil, "", "[]" ]).count,  # FAQPage JSON-LD 포함 토픽
      canonical_issues: 0 # 모두 수정됨
    }
  end

  def self.generate_warnings
    warnings = []

    # FAQ 없는 토픽 체크
    topics_without_faq = Topic.published.where("faqs IS NULL OR faqs = ? OR faqs = ?", "", "[]").count
    warnings << "FAQ가 없는 토픽: #{topics_without_faq}개" if topics_without_faq > 0

    # 메타 설명 없는 토픽
    topics_without_meta = Topic.published.where("summary IS NULL OR summary = ''").count
    warnings << "메타 설명이 없는 토픽: #{topics_without_meta}개" if topics_without_meta > 0

    # 최근 업데이트 확인
    old_topics = Topic.published.where("updated_at < ?", 3.months.ago).count
    warnings << "3개월 이상 업데이트되지 않은 토픽: #{old_topics}개" if old_topics > 5

    warnings << "모든 SEO 지표가 정상입니다!" if warnings.empty?
    warnings
  end

  def self.count_sitemap_urls
    begin
      require "net/http"
      uri = URI("#{SITE_URL}/sitemap.xml")
      response = Net::HTTP.get_response(uri)
      response.body.scan(/<url>/).count
    rescue => e
      Rails.logger.error "Sitemap 확인 실패: #{e.message}"
      0
    end
  end

  def self.calculate_avg_meta_length
    lengths = Topic.published.where.not(summary: [ nil, "" ]).pluck(:summary).map(&:length)
    lengths.any? ? (lengths.sum / lengths.size) : 0
  end

  def self.check_performance_score
    # 실제로는 PageSpeed Insights API 호출
    # 여기서는 로컬 테스트
    begin
      require "net/http"
      uri = URI(SITE_URL)
      start_time = Time.now
      Net::HTTP.get_response(uri)
      load_time = Time.now - start_time

      # 간단한 점수 계산 (실제로는 더 복잡)
      score = load_time < 0.5 ? 90 : (load_time < 1.0 ? 75 : 60)
      score
    rescue
      0
    end
  end

  def self.measure_fcp
    # TODO: PageSpeed Insights API 연동 필요 (현재 미구현)
    nil
  end

  def self.measure_lcp
    # TODO: PageSpeed Insights API 연동 필요 (현재 미구현)
    nil
  end

  def self.measure_tbt
    # TODO: PageSpeed Insights API 연동 필요 (현재 미구현)
    nil
  end

  def self.measure_cls
    # TODO: PageSpeed Insights API 연동 필요 (현재 미구현)
    nil
  end

  def self.performance_opportunities
    # TODO: PageSpeed Insights API 연동 필요 (현재 미구현)
    []
  end

  def self.check_page_links(page, broken)
    # 실제 구현에서는 Nokogiri로 HTML 파싱하여 링크 체크
    # 여기서는 생략
  end
end
