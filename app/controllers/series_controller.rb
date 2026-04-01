class SeriesController < ApplicationController
  def show
    @series_slug = params[:slug]
    korean_series = Guide.series_by_slug(@series_slug)
    raise ActionController::RoutingError, "Not Found" unless korean_series

    @series_name = korean_series.tr("_", " ")
    @episodes = Rails.cache.fetch("guides/series/#{korean_series}", expires_in: 1.hour) do
      Guide.published.where(series: korean_series).order(series_order: :asc).to_a
    end

    raise ActionController::RoutingError, "Not Found" if @episodes.empty?

    @first_episode = @episodes.first
    @sample_flashcards = @first_episode&.rich_media&.dig("flashcards")&.first(3) || []
    @other_series = Guide::SERIES_SLUG_MAP.reject { |_, slug| slug == @series_slug }

    expires_in 10.minutes, public: true, stale_while_revalidate: 1.hour

    canonical_url = "https://silmu.kr/series/#{@series_slug}"
    set_meta_tags(
      title: "#{@series_name} — #{@episodes.size}편 완전정복 시리즈",
      description: "#{@series_name} 시리즈 #{@episodes.size}편. 마인드맵·플래시카드와 함께 단계별로 완전 마스터하세요. 공무원 실무에서 바로 쓸 수 있는 법령 해설과 사례 중심 구성.",
      keywords: "#{@series_name}, 공무원 실무, 완전정복 시리즈, 법령 가이드",
      og: {
        title: "#{@series_name} #{@episodes.size}편 완전정복 — 실무.kr",
        description: "#{@series_name} 시리즈 #{@episodes.size}편. 마인드맵·플래시카드와 함께 단계별로 완전 마스터. 공무원 법령 실무 가이드.",
        url: canonical_url,
        image: "https://silmu.kr/og-image.webp",
        type: "website"
      },
      canonical: canonical_url,
      twitter: {
        card: "summary_large_image",
        title: "#{@series_name} #{@episodes.size}편 완전정복 — 실무.kr",
        description: "#{@series_name} 시리즈 #{@episodes.size}편. 마인드맵·플래시카드와 함께 단계별로 완전 마스터."
      }
    )
  rescue ActionController::RoutingError
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
