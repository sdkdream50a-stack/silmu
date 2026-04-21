class Admin::TopicCommentsController < Admin::BaseController
  include Pagy::Method

  def index
    scope = TopicComment.includes(:user).order(created_at: :desc)
    scope = scope.where(comment_type: params[:comment_type]) if params[:comment_type].present?
    scope = scope.where(hidden: params[:hidden] == "true") if params[:hidden].present?

    @pagy, @comments = pagy(:offset, scope, limit: 30)

    @stats = {
      total:     TopicComment.count,
      questions: TopicComment.where(comment_type: :question).count,
      unanswered: TopicComment.where(comment_type: :question)
                              .where.not(topic_slug: TopicComment.where(comment_type: :answer).select(:topic_slug)).count,
      hidden:    TopicComment.where(hidden: true).count
    }
  end

  def hide
    TopicComment.find(params[:id]).update!(hidden: true)
    redirect_to admin_topic_comments_path, notice: "숨김 처리했습니다."
  end

  def unhide
    TopicComment.find(params[:id]).update!(hidden: false)
    redirect_to admin_topic_comments_path, notice: "숨김 해제했습니다."
  end

  def destroy
    TopicComment.find(params[:id]).destroy!
    redirect_to admin_topic_comments_path, notice: "삭제했습니다."
  end
end
