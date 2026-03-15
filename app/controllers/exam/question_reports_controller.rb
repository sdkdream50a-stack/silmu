module Exam
  class QuestionReportsController < ApplicationController
    layout false

    def create
      body = params[:body].to_s.strip.first(500)
      if body.length < 5
        return render json: { error: "5자 이상 입력해주세요." }, status: :unprocessable_entity
      end
      ExamQuestionReport.create!(
        question_id: params[:question_id].to_i,
        user_id: current_user&.id,
        body: body
      )
      render json: { success: true }
    rescue => e
      render json: { error: "제보에 실패했습니다." }, status: :unprocessable_entity
    end
  end
end
