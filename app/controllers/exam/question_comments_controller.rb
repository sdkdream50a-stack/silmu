module Exam
  class QuestionCommentsController < ApplicationController
    layout false

    # GET /questions/:question_id/comments
    def index
      comments = ExamQuestionComment
        .where(question_id: params[:question_id])
        .order(created_at: :desc)
        .limit(20)
        .map do |c|
          {
            id: c.id,
            body: c.body,
            author: c.author_display_name,
            created_at: c.created_at.strftime("%Y.%m.%d"),
            likes_count: c.likes_count
          }
        end
      render json: comments
    end

    # POST /questions/:question_id/comments
    def create
      unless user_signed_in?
        return render json: { error: "댓글 작성은 로그인이 필요합니다.", login_required: true }, status: :unauthorized
      end

      comment = ExamQuestionComment.create!(
        question_id: params[:question_id].to_i,
        user: current_user,
        body: params[:body].to_s.strip.first(500),
        author_name: params[:author_name].to_s.strip.first(20).presence
      )
      render json: {
        id: comment.id,
        body: comment.body,
        author: comment.author_display_name,
        created_at: comment.created_at.strftime("%Y.%m.%d"),
        likes_count: 0
      }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "QuestionCommentsController error: #{e.message}"
      render json: { error: "댓글 작성에 실패했습니다." }, status: :unprocessable_entity
    end
  end
end
