# Created: 2026-02-24 22:20
# GA4 Analytics 대시보드 컨트롤러 (Admin 전용)

class Admin::AnalyticsController < Admin::BaseController
  def index
    @days = (params[:days] || 7).to_i
    @days = 7 unless [1, 7, 14, 30].include?(@days)

    begin
      ga4_service = Ga4Service.new
      @data = ga4_service.dashboard_data(days: @days)
    rescue => e
      Rails.logger.error "GA4 Analytics error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      flash.now[:alert] = "Google Analytics 데이터를 불러올 수 없습니다. credentials 설정을 확인해주세요."
      @data = nil
    end
  end
end
