class TopicCommentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def create
    @topic = Topic.find_by!(slug: params[:topic_slug], published: true)
    @comment = TopicComment.new(comment_params)
    @comment.user = current_user
    @comment.topic_slug = @topic.slug

    # AI 모더레이션
    moderation = TopicComment.moderate_with_ai(@comment.body)
    if moderation["approved"] == false
      respond_to do |format|
        format.html { redirect_back fallback_location: topic_path(@topic.slug), alert: "댓글이 등록 기준에 맞지 않습니다: #{moderation['reason']}" }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "comment-form-#{@topic.slug}",
            partial: "topic_comments/form",
            locals: { topic: @topic, comment: @comment, error: moderation["reason"] }
          )
        }
      end
      return
    end

    if @comment.save
      respond_to do |format|
        format.html { redirect_back fallback_location: topic_path(@topic.slug), notice: "댓글이 등록되었습니다." }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend(
              "topic-comments-#{@topic.slug}",
              partial: "topic_comments/comment",
              locals: { comment: @comment }
            ),
            turbo_stream.replace(
              "comment-form-#{@topic.slug}",
              partial: "topic_comments/form",
              locals: { topic: @topic, comment: TopicComment.new, error: nil }
            )
          ]
        }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: topic_path(@topic.slug), alert: @comment.errors.full_messages.join(", ") }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "comment-form-#{@topic.slug}",
            partial: "topic_comments/form",
            locals: { topic: @topic, comment: @comment, error: @comment.errors.full_messages.join(", ") }
          )
        }
      end
    end
  end

  def like
    comment = TopicComment.find(params[:id])
    comment.increment!(:likes_count)
    head :ok
  end

  private

  def comment_params
    params.require(:topic_comment).permit(:body, :comment_type, :parent_id)
  end
end
