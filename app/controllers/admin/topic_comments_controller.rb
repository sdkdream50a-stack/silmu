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

  # Sprint #5-D — admin 공식 답변 작성 (Krug + 카페 모델 권위자)
  def answer
    parent = TopicComment.find(params[:id])
    body = params[:body].to_s.strip
    if body.blank? || body.length < 5
      redirect_to admin_topic_comments_path, alert: "답변 본문은 5자 이상이어야 합니다."
      return
    end

    answer_record = TopicComment.create!(
      topic_slug:   parent.topic_slug,
      parent_id:    parent.id,
      comment_type: :answer,
      body:         body,
      user_id:      current_user&.id,
      is_official:  true,
      hidden:       false
    )

    redirect_to admin_topic_comments_path,
                notice: "공식 답변을 작성했습니다 (##{answer_record.id})."
  end
end
