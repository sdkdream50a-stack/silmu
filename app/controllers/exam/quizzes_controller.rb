module Exam
  class QuizzesController < ApplicationController
    layout "exam"

    # 문제에서 뷰에 필요한 필드만 추출 (불필요한 데이터 전송 방지)
    QUESTION_FIELDS = %i[id question options correct explanation subject_id chapter_num].freeze

    # GET /quiz/mini — 랜덤 10문제 미니 퀴즈
    def mini
      @questions = ExamQuestions.all.sample(10).map { |q| q.slice(*QUESTION_FIELDS) }
      @chapter_map = ExamCurriculum.chapter_map
      set_meta_tags(
        title: "미니 퀴즈 — 랜덤 10문제",
        description: "공공조달관리사 랜덤 10문제 미니 퀴즈. 빈 시간에 짧게 실력을 점검하세요. 즉시 채점·상세 해설 제공.",
        keywords: "공공조달관리사 미니 퀴즈, 랜덤 문제, 빠른 복습"
      )
    end

    # GET /quiz — 과목 선택 화면
    def index
      @subjects = ExamCurriculum::SUBJECTS

      # 정적 콘텐츠이므로 HTTP 캐싱
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "모의고사",
        description: "공공조달관리사 4지선다 모의고사. 1~4권 과목별·전체 #{ExamQuestions.count}문제, 즉시 채점·상세 해설 제공.",
        keywords: "공공조달관리사 모의고사, 공공조달 시험 문제, 국가기술자격 모의고사"
      )
    end

    # GET /quiz/simulation — 실전 시험 모드 (100분 타이머 + 랜덤 + 일괄채점)
    def simulation
      @questions = ExamQuestions.all.map { |q| q.slice(*QUESTION_FIELDS) }

      # 문제 데이터가 변경되지 않으므로 HTTP 캐싱
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "실전 시험 모드",
        description: "공공조달관리사 실전 시험 모드 — #{@questions.size}문제 100분 타이머. 랜덤 순서로 풀고 마지막에 일괄 채점합니다.",
        keywords: "공공조달관리사 실전 시험, 공공조달 모의고사 타이머"
      )
    end

    # GET /quiz/analysis — 학습 분석 대시보드
    def analysis
      # 정적 페이지 (JS가 localStorage에서 데이터 로드)
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "학습 분석 대시보드",
        description: "과목별 챕터 진도, 모의고사 점수, 오답 분포를 한눈에 확인하세요. 공공조달관리사 합격을 위한 맞춤 학습 추천.",
        keywords: "공공조달관리사 학습 분석, 공공조달 오답 분석, 시험 대비 학습 추적"
      )
    end

    # GET /quiz/wrong — 오답 노트 재풀이 (모든 문제를 내려보내고 클라이언트에서 필터)
    def wrong
      raw = ExamQuestions.all.map { |q| q.slice(*QUESTION_FIELDS) }
      @all_questions = ExamQuestions.with_difficulty(raw)
      @chapter_map = ExamCurriculum.chapter_map

      # 문제 데이터가 변경되지 않으므로 HTTP 캐싱
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "오답 노트",
        description: "틀렸던 문제만 다시 풀어보는 오답 노트. 공공조달관리사 모의고사 오답을 반복 학습하여 완벽하게 정복하세요.",
        keywords: "공공조달관리사 오답노트, 오답 복습, 공공조달 시험"
      )
    end

    # GET /quiz/subject/:subject_id/chapter/:chapter_num — 챕터별 문제 풀기
    def chapter
      @subject = ExamCurriculum.find_subject(params[:subject_id])
      return redirect_to exam_quiz_index_path, alert: "존재하지 않는 과목입니다." unless @subject

      @chapter_num = params[:chapter_num].to_i
      @chapter = ExamCurriculum.find_chapter(params[:subject_id], params[:chapter_num])
      return redirect_to exam_subject_path(@subject[:id]), alert: "존재하지 않는 챕터입니다." unless @chapter

      raw_questions = ExamQuestions.by_chapter(@subject[:id], @chapter_num)
                                   .map { |q| q.slice(*QUESTION_FIELDS) }
      @questions = ExamQuestions.with_difficulty(raw_questions)
      @subject_id = @subject[:id]
      @quiz_title = "#{@subject[:number]} 제#{@chapter_num}장 문제"
      @quiz_subtitle = @chapter[:title]
      @color = @subject[:color]
      @estimated_minutes = (@questions.size * 1.5).ceil
      @back_path = exam_subject_chapter_path(@subject[:id], @chapter_num)
      @chapter_map = ExamCurriculum.chapter_map

      set_meta_tags(
        title: "#{@subject[:number]} 제#{@chapter_num}장 — #{@chapter[:title]} 문제",
        description: "공공조달관리사 #{@subject[:number]} 제#{@chapter_num}장 #{@chapter[:title]} 관련 #{@questions.size}문제. 4지선다 즉시 채점·상세 해설로 챕터 학습을 완성하세요.",
        keywords: "공공조달관리사 #{@chapter[:title]} 문제, #{@subject[:title]} #{@chapter_num}장 모의고사, 공공조달관리사 챕터 문제풀기",
        og: {
          title: "#{@subject[:number]} 제#{@chapter_num}장 #{@chapter[:title]} 문제 | 공공조달관리사",
          description: "공공조달관리사 #{@subject[:number]} 제#{@chapter_num}장 #{@chapter[:title]} #{@questions.size}문제. 즉시 채점과 상세 해설로 실력을 확인하세요.",
          url: "https://exam.silmu.kr/quiz/subject/#{@subject[:id]}/chapter/#{@chapter_num}",
          type: "website"
        }
      )

      render :show
    end

    # GET /quiz/:id — 실제 퀴즈 (id: 1~4 = 과목별, 'all' = 전체)
    def show
      @subject_id = params[:id]

      if @subject_id == "all"
        raw = ExamQuestions.all.map { |q| q.slice(*QUESTION_FIELDS) }
        @questions = ExamQuestions.with_difficulty(raw)
        @quiz_title = "전체 모의고사"
        @quiz_subtitle = "4권 전체 — #{@questions.size}문제"
        @subject = nil
        @color = "blue"
      else
        subject_id = @subject_id.to_i
        @subject = ExamCurriculum.find_subject(subject_id)
        return redirect_to exam_quiz_index_path, alert: "존재하지 않는 과목입니다." unless @subject

        raw = ExamQuestions.by_subject(subject_id).map { |q| q.slice(*QUESTION_FIELDS) }
        @questions = ExamQuestions.with_difficulty(raw)
        @quiz_title = "#{@subject[:number]} 모의고사"
        @quiz_subtitle = @subject[:title]
        @color = @subject[:color]
      end

      @estimated_minutes = (@questions.size * 1.5).ceil
      @chapter_map = ExamCurriculum.chapter_map
      set_meta_tags(
        title: @quiz_title,
        description: "공공조달관리사 #{@quiz_title} — #{@questions.size}문제 4지선다. 즉시 채점과 상세 해설로 실전 감각을 키우세요.",
        keywords: "공공조달관리사 #{@quiz_title}, 공공조달 시험 모의고사, 국가기술자격 문제풀이",
        og: {
          title: "#{@quiz_title} | 공공조달관리사 모의고사",
          description: "공공조달관리사 #{@quiz_title} #{@questions.size}문제. 즉시 채점과 상세 해설로 실전 감각을 키우세요.",
          url: "https://exam.silmu.kr/quiz/#{@subject_id}",
          type: "website"
        }
      )
    end
  end
end
