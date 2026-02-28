module Exam
  class QuizzesController < ApplicationController
    layout "exam"

    # GET /quiz — 과목 선택 화면
    def index
      @subjects = ExamCurriculum::SUBJECTS
    end

    # GET /quiz/:id — 실제 퀴즈 (id: 1~4 = 과목별, 'all' = 전체)
    def show
      @subject_id = params[:id]

      if @subject_id == "all"
        @questions = ExamQuestions.all.map { |q| q.slice(:id, :question, :options, :correct, :explanation, :subject_id) }
        @quiz_title = "전체 모의고사"
        @quiz_subtitle = "4권 전체 — #{@questions.size}문제"
        @subject = nil
        @color = "blue"
      else
        subject_id = @subject_id.to_i
        @subject = ExamCurriculum.find_subject(subject_id)
        return redirect_to exam_quiz_index_path, alert: "존재하지 않는 과목입니다." unless @subject

        @questions = ExamQuestions.by_subject(subject_id).map { |q| q.slice(:id, :question, :options, :correct, :explanation, :subject_id) }
        @quiz_title = "#{@subject[:number]} 모의고사"
        @quiz_subtitle = @subject[:title]
        @color = @subject[:color]
      end

      @estimated_minutes = (@questions.size * 1.5).ceil
    end
  end
end
