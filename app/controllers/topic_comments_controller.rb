class TopicCommentsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :like ]

  def create
    @topic = Topic.find_by!(slug: params[:topic_slug], published: true)
    @comment = TopicComment.new(comment_params)
    @comment.user = current_user
    @comment.topic_slug = @topic.slug

    if @comment.save
      TopicCommentModerationJob.perform_later(@comment.id)
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
