class TaskGuidesController < ApplicationController
  def show
    title = params[:title].to_s.strip
    category = params[:category].to_s.strip.presence

    if title.blank?
      render json: { success: false, error: "업무 제목이 필요합니다." }, status: :bad_request
      return
    end

    guide = TaskGuide.find_by(task_title: title, status: :completed)

    if guide
      render json: { success: true, title: guide.task_title, category: guide.category, content: guide.content }
      return
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
end
