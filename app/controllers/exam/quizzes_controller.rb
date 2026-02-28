module Exam
  class QuizzesController < ApplicationController
    layout "exam"

    # GET /quiz — 과목 선택 화면
    def index
      @subjects = ExamCurriculum::SUBJECTS
      set_meta_tags(
        title: "모의고사",
        description: "공공조달관리사 4지선다 모의고사. 1~4권 과목별·전체 #{ExamQuestions.count}문제, 즉시 채점·상세 해설 제공.",
        keywords: "공공조달관리사 모의고사, 공공조달 시험 문제, 국가기술자격 모의고사"
      )
    end

    # GET /quiz/wrong — 오답 노트 재풀이 (모든 문제를 내려보내고 클라이언트에서 필터)
    def wrong
      @all_questions = ExamQuestions.all.map { |q| q.slice(:id, :question, :options, :correct, :explanation, :subject_id) }
      set_meta_tags(
        title: "오답 노트",
        description: "틀렸던 문제만 다시 풀어보는 오답 노트. 공공조달관리사 모의고사 오답을 반복 학습하여 완벽하게 정복하세요.",
        keywords: "공공조달관리사 오답노트, 오답 복습, 공공조달 시험"
      )
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
      set_meta_tags(
        title: @quiz_title,
        description: "공공조달관리사 #{@quiz_title} — #{@questions.size}문제 4지선다. 즉시 채점과 상세 해설로 실전 감각을 키우세요.",
        keywords: "공공조달관리사 #{@quiz_title}, 공공조달 시험 모의고사"
      )
    end
  end
end
