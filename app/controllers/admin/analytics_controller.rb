# Created: 2026-02-24 22:20
# GA4 Analytics 대시보드 컨트롤러 (Admin 전용)

class Admin::AnalyticsController < Admin::BaseController
  def index
    @days = (params[:days] || 7).to_i
    @days = 7 unless [ 1, 7, 14, 30 ].include?(@days)

    begin
      ga4_service = Ga4Service.new
      @data = ga4_service.dashboard_data(days: @days)
      @roi_snapshot_labels = AnalyticsSnapshot.distinct.pluck(:label).sort
      @roi_compare = build_roi_compare(ga4_service)
    rescue => e
      Rails.logger.error "GA4 Analytics error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      flash.now[:alert] = "Google Analytics 데이터를 불러올 수 없습니다. credentials 설정을 확인해주세요."
      @data = nil
      @roi_snapshot_labels = []
      @roi_compare = nil
    end
  end

  private

  # P8 ROI — 베이스라인 라벨이 지정되면 현재 GA4 지표와 비교
  def build_roi_compare(ga4_service)
    baseline_label = params[:baseline].presence
    return nil unless baseline_label

    paths = Analytics::RoiScope.all_paths
    baseline_rows = AnalyticsSnapshot.for_label(baseline_label).index_by(&:page_path)
    return nil if baseline_rows.empty?

    current = ga4_service.page_metrics(paths: paths, days: @days)
    paths.map do |path|
      b = baseline_rows[path]
      c = current[path] || {}
      {
        path:           path,
        before_pv:      b&.pageviews || 0,
        after_pv:       c[:pageviews] || 0,
        before_users:   b&.users || 0,
        after_users:    c[:users] || 0,
        before_bounce:  b&.bounce_rate || 0.0,
        after_bounce:   c[:bounce_rate] || 0.0,
        delta_pct:      delta_pct(b&.pageviews || 0, c[:pageviews] || 0)
      }
    end
  end

  def delta_pct(before, after)
    return 0.0 if before.zero? && after.zero?
    return 100.0 if before.zero?
    ((after - before) * 100.0 / before).round(1)
  end
end
