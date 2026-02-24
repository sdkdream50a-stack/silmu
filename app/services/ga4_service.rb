# Created: 2026-02-24 22:15
# Google Analytics Data API v1 서비스 클래스
# 모든 GA4 지표를 수집하고 5분 캐시 적용

require "google/analytics/data/v1beta"

class Ga4Service
  PROPERTY_ID = "524141122"
  CACHE_TTL = 5.minutes

  def initialize
    @client = Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |config|
      config.credentials = credentials_hash
    end
  end

  # 실시간 활성 사용자
  def real_time_users
    Rails.cache.fetch("ga4/real_time_users", expires_in: 1.minute) do
      request = Google::Analytics::Data::V1beta::RunRealtimeReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        metrics: [{ name: "activeUsers" }]
      )

      response = @client.run_realtime_report(request)
      response.rows.first&.metric_values&.first&.value&.to_i || 0
    end
  rescue => e
    Rails.logger.error "GA4 real_time_users error: #{e.message}"
    0
  end

  # 일별 활성 사용자 (DAU) - 최근 30일
  def daily_active_users(days: 30)
    Rails.cache.fetch("ga4/daily_active_users_#{days}d", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [{ start_date: "#{days}daysAgo", end_date: "today" }],
        dimensions: [{ name: "date" }],
        metrics: [{ name: "activeUsers" }],
        order_bys: [{ dimension: { dimension_name: "date" }, desc: false }]
      )

      response = @client.run_report(request)
      response.rows.map do |row|
        {
          date: row.dimension_values[0].value,
          active_users: row.metric_values[0].value.to_i
        }
      end
    end
  rescue => e
    Rails.logger.error "GA4 daily_active_users error: #{e.message}"
    []
  end

  # 주별/월별 활성 사용자 (WAU/MAU)
  def weekly_monthly_users
    Rails.cache.fetch("ga4/weekly_monthly_users", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [
          { start_date: "7daysAgo", end_date: "today" },
          { start_date: "30daysAgo", end_date: "today" }
        ],
        metrics: [{ name: "activeUsers" }]
      )

      response = @client.run_report(request)
      {
        wau: response.rows[0]&.metric_values&.first&.value&.to_i || 0,
        mau: response.rows[0]&.metric_values&.last&.value&.to_i || 0
      }
    end
  rescue => e
    Rails.logger.error "GA4 weekly_monthly_users error: #{e.message}"
    { wau: 0, mau: 0 }
  end

  # 페이지뷰 (전체 및 페이지별 Top 10)
  def page_views(days: 7)
    Rails.cache.fetch("ga4/page_views_#{days}d", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [{ start_date: "#{days}daysAgo", end_date: "today" }],
        dimensions: [{ name: "pagePath" }, { name: "pageTitle" }],
        metrics: [{ name: "screenPageViews" }],
        order_bys: [{ metric: { metric_name: "screenPageViews" }, desc: true }],
        limit: 10
      )

      response = @client.run_report(request)
      {
        total: response.row_count || 0,
        top_pages: response.rows.map do |row|
          {
            path: row.dimension_values[0].value,
            title: row.dimension_values[1].value,
            views: row.metric_values[0].value.to_i
          }
        end
      }
    end
  rescue => e
    Rails.logger.error "GA4 page_views error: #{e.message}"
    { total: 0, top_pages: [] }
  end

  # 유입 경로 (Google/Naver/Direct/Social)
  def traffic_sources(days: 7)
    Rails.cache.fetch("ga4/traffic_sources_#{days}d", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [{ start_date: "#{days}daysAgo", end_date: "today" }],
        dimensions: [
          { name: "sessionSource" },
          { name: "sessionMedium" }
        ],
        metrics: [
          { name: "sessions" },
          { name: "activeUsers" }
        ],
        order_bys: [{ metric: { metric_name: "sessions" }, desc: true }],
        limit: 10
      )

      response = @client.run_report(request)
      response.rows.map do |row|
        {
          source: row.dimension_values[0].value,
          medium: row.dimension_values[1].value,
          sessions: row.metric_values[0].value.to_i,
          users: row.metric_values[1].value.to_i
        }
      end
    end
  rescue => e
    Rails.logger.error "GA4 traffic_sources error: #{e.message}"
    []
  end

  # 인기 페이지 Top 10
  def top_pages(days: 7)
    Rails.cache.fetch("ga4/top_pages_#{days}d", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [{ start_date: "#{days}daysAgo", end_date: "today" }],
        dimensions: [{ name: "pagePath" }, { name: "pageTitle" }],
        metrics: [
          { name: "screenPageViews" },
          { name: "activeUsers" }
        ],
        order_bys: [{ metric: { metric_name: "screenPageViews" }, desc: true }],
        limit: 10
      )

      response = @client.run_report(request)
      response.rows.map do |row|
        {
          path: row.dimension_values[0].value,
          title: row.dimension_values[1].value,
          views: row.metric_values[0].value.to_i,
          users: row.metric_values[1].value.to_i
        }
      end
    end
  rescue => e
    Rails.logger.error "GA4 top_pages error: #{e.message}"
    []
  end

  # 신규 vs 재방문 사용자
  def new_vs_returning(days: 7)
    Rails.cache.fetch("ga4/new_vs_returning_#{days}d", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [{ start_date: "#{days}daysAgo", end_date: "today" }],
        dimensions: [{ name: "newVsReturning" }],
        metrics: [{ name: "activeUsers" }]
      )

      response = @client.run_report(request)
      result = { new: 0, returning: 0 }

      response.rows.each do |row|
        type = row.dimension_values[0].value
        count = row.metric_values[0].value.to_i

        if type == "new"
          result[:new] = count
        elsif type == "returning"
          result[:returning] = count
        end
      end

      result
    end
  rescue => e
    Rails.logger.error "GA4 new_vs_returning error: #{e.message}"
    { new: 0, returning: 0 }
  end

  # 참여도 지표 (평균 체류 시간, 이탈률)
  def engagement_metrics(days: 7)
    Rails.cache.fetch("ga4/engagement_metrics_#{days}d", expires_in: CACHE_TTL) do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(
        property: "properties/#{PROPERTY_ID}",
        date_ranges: [{ start_date: "#{days}daysAgo", end_date: "today" }],
        metrics: [
          { name: "averageSessionDuration" },
          { name: "bounceRate" },
          { name: "engagementRate" }
        ]
      )

      response = @client.run_report(request)
      row = response.rows.first

      {
        avg_session_duration: row&.metric_values&.[](0)&.value&.to_f&.round(2) || 0,
        bounce_rate: (row&.metric_values&.[](1)&.value&.to_f&.*(100))&.round(2) || 0,
        engagement_rate: (row&.metric_values&.[](2)&.value&.to_f&.*(100))&.round(2) || 0
      }
    end
  rescue => e
    Rails.logger.error "GA4 engagement_metrics error: #{e.message}"
    { avg_session_duration: 0, bounce_rate: 0, engagement_rate: 0 }
  end

  # 대시보드 전체 데이터 (한 번에 가져오기)
  def dashboard_data(days: 7)
    {
      real_time: real_time_users,
      daily_users: daily_active_users(days: days),
      weekly_monthly: weekly_monthly_users,
      page_views: page_views(days: days),
      traffic_sources: traffic_sources(days: days),
      top_pages: top_pages(days: days),
      new_vs_returning: new_vs_returning(days: days),
      engagement: engagement_metrics(days: days),
      last_updated: Time.current
    }
  end

  private

  def credentials_hash
    creds = Rails.application.credentials.google_analytics[:credentials]

    # String 키를 Symbol 키로 변환 (google-analytics-data gem 요구사항)
    {
      type: creds[:type],
      project_id: creds[:project_id],
      private_key_id: creds[:private_key_id],
      private_key: creds[:private_key],
      client_email: creds[:client_email],
      client_id: creds[:client_id],
      auth_uri: creds[:auth_uri],
      token_uri: creds[:token_uri],
      auth_provider_x509_cert_url: creds[:auth_provider_x509_cert_url],
      client_x509_cert_url: creds[:client_x509_cert_url]
    }
  end
end
