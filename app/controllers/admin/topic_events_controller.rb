# frozen_string_literal: true

class Admin::TopicEventsController < Admin::BaseController
  def index
    last_30d = TopicEvent.where("created_at > ?", 30.days.ago)

    @stats = {
      total:        last_30d.count,
      scroll_depth: last_30d.scroll_depth.count,
      time_on_page: last_30d.time_on_page.count,
      faq_open:     last_30d.faq_open.count
    }

    # 토픽별 평균 scroll·time (30일)
    @per_topic = last_30d
      .group(:topic_slug, :event_type)
      .pluck(:topic_slug, :event_type, Arel.sql("AVG(event_value)::int AS avg_v"), Arel.sql("COUNT(*) AS cnt"))
      .group_by(&:first)
      .map do |slug, rows|
        h = { slug: slug, total: 0 }
        rows.each do |_, type, avg, cnt|
          h[type.to_sym] = { avg: avg, cnt: cnt }
          h[:total] += cnt
        end
        h
      end
      .sort_by { |h| -h[:total] }
      .first(30)
  end
end
