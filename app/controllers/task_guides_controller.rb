class TaskGuidesController < ApplicationController
  # IP당 분당 10회, 일일 50회 제한 (캐싱 우회 악용 방지)
  RATE_LIMIT = 10
  RATE_PERIOD = 1.minute
  DAILY_LIMIT = 50

  def show
    title = params[:title].to_s.strip
    category = params[:category].to_s.strip.presence

    if title.blank?
      render json: { success: false, error: "업무 제목이 필요합니다." }, status: :bad_request
      return
    end

    # 캐싱된 가이드는 Rate Limit 없이 즉시 반환
    guide = TaskGuide.find_by(task_title: title, status: :completed)

    if guide
      render json: { success: true, title: guide.task_title, category: guide.category, content: guide.content }
      return
    end

    # 새로 생성해야 하는 경우에만 Rate Limit 적용
    if rate_limited?
      return render json: { success: false, error: "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요." }, status: :too_many_requests
    end

    # API 키 확인
    unless ENV["ANTHROPIC_API_KEY"].present?
      render json: { success: false, error: "가이드를 생성할 수 없습니다." }
      return
    end

    service = TaskGuideService.new
    guide = service.generate(title, category)

    if guide&.completed?
      render json: { success: true, title: guide.task_title, category: guide.category, content: guide.content }
    else
      render json: { success: false, error: "가이드 생성에 실패했습니다. 잠시 후 다시 시도해주세요." }
    end
  end

  private

  def rate_limited?
    ip = request.remote_ip

    minute_key = "task_guide_rate:#{ip}"
    minute_count = Rails.cache.read(minute_key).to_i
    return true if minute_count >= RATE_LIMIT

    daily_key = "task_guide_daily:#{ip}:#{Date.today}"
    daily_count = Rails.cache.read(daily_key).to_i
    return true if daily_count >= DAILY_LIMIT

    Rails.cache.write(minute_key, minute_count + 1, expires_in: RATE_PERIOD)
    Rails.cache.write(daily_key, daily_count + 1, expires_in: 24.hours)
    false
  end
end
