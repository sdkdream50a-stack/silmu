module Exam
  class QuestionCommentsController < ApplicationController
    layout false
    before_action :set_comment, only: [ :destroy, :like, :report ]

    # GET /questions/:question_id/comments
    def index
      comments = ExamQuestionComment.by_question(params[:question_id]).limit(30).map do |c|
        {
          id: c.id,
          body: c.body,
          author: c.author_display_name,
          created_at: c.created_at.strftime("%Y.%m.%d"),
          likes_count: c.likes_count,
          mine: user_signed_in? && c.user_id == current_user.id
        }
      end

      # 로그인 유저의 숨겨진 댓글(AI 검토 중) 포함
      if user_signed_in?
        hidden_mine = ExamQuestionComment
          .where(question_id: params[:question_id], user_id: current_user.id, hidden: true)
          .order(created_at: :desc)
          .limit(5)
          .map do |c|
            {
              id: c.id,
              body: c.body,
              author: c.author_display_name,
              created_at: c.created_at.strftime("%Y.%m.%d"),
              likes_count: c.likes_count,
              mine: true,
              pending_review: true
            }
          end
        comments = hidden_mine + comments
      end

      render json: comments
    end

    # POST /questions/:question_id/comments
    def create
      unless user_signed_in?
        return render json: { error: "댓글 작성은 로그인이 필요합니다.", login_required: true }, status: :unauthorized
      end

      body = params[:body].to_s.strip.first(500)
      if body.length < 5
        return render json: { error: "댓글은 5자 이상 입력해주세요." }, status: :unprocessable_entity
      end

      question_text = params[:question_text].to_s
      comment = ExamQuestionComment.create!(
        question_id: params[:question_id].to_i,
        user: current_user,
        body: body,
        author_name: params[:author_name].to_s.strip.first(20).presence
      )
      # AI 모더레이션 비동기 처리 (응답 지연 없음)
      ExamCommentModerationJob.perform_later(comment.id, question_text)
      render json: {
        id: comment.id,
        body: comment.body,
        author: comment.author_display_name,
        created_at: comment.created_at.strftime("%Y.%m.%d"),
        likes_count: 0,
        mine: true
      }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "QuestionCommentsController#create error: #{e.message}"
      render json: { error: "댓글 작성에 실패했습니다." }, status: :unprocessable_entity
    end

    # DELETE /questions/:question_id/comments/:id
    def destroy
      unless user_signed_in? && @comment.user_id == current_user.id
        return render json: { error: "권한이 없습니다." }, status: :forbidden
      end
      @comment.destroy!
      render json: { success: true }
    end

    # POST /questions/:question_id/comments/:id/like
    def like
      @comment.increment!(:likes_count)
      render json: { likes_count: @comment.likes_count }
    end

    # POST /questions/:question_id/comments/:id/report
    def report
      @comment.increment!(:reported_count)
      # 3회 이상 신고 시 자동 숨김 + AI 재검토
      if @comment.reported_count >= 3 && !@comment.hidden?
        @comment.update!(hidden: true)
        Rails.logger.info "[CommentModeration] 댓글 #{@comment.id} 신고 3회로 자동 숨김"
      end
      render json: { success: true }
    end

    private

    def set_comment
      @comment = ExamQuestionComment.find(params[:id])
    end
  end
end
