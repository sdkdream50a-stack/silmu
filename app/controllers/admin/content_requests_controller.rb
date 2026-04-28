# frozen_string_literal: true

class Admin::ContentRequestsController < Admin::BaseController
  include Pagy::Method

  def index
    scope = ContentRequest.priority_h
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(source: params[:source]) if params[:source].present?

    @pagy, @requests = pagy(:offset, scope, limit: 50)

    @stats = {
      total:       ContentRequest.count,
      open:        ContentRequest.open.count,
      in_progress: ContentRequest.where(status: "in_progress").count,
      done:        ContentRequest.where(status: "done").count,
      from_feedback: ContentRequest.where(source: "feedback_memo").count
    }
  end

  def update
    cr = ContentRequest.find(params[:id])
    cr.update(content_request_params)
    redirect_to admin_content_requests_path, notice: "업데이트했습니다."
  end

  def destroy
    ContentRequest.find(params[:id]).destroy
    redirect_to admin_content_requests_path, notice: "삭제했습니다."
  end

  private

  def content_request_params
    params.require(:content_request).permit(:status, :priority, :title, :memo, :topic_slug)
  end
end
