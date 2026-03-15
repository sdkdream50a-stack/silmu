module Exam
  class QuizzesController < ApplicationController
    layout "exam"

    # GET /quiz/mini — 랜덤 10문제 미니 퀴즈
    def mini
      @questions = ExamQuestions.all_sliced_with_difficulty.sample(10)
      @chapter_map = ExamCurriculum.chapter_map
      set_meta_tags(
        title: "미니 퀴즈 — 랜덤 10문제",
        description: "공공조달관리사 랜덤 10문제 미니 퀴즈. 빈 시간에 짧게 실력을 점검하세요. 즉시 채점·상세 해설 제공.",
        keywords: "공공조달관리사 미니 퀴즈, 랜덤 문제, 빠른 복습",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    # GET /quiz — 과목 선택 화면
    def index
      @exam_subjects = ExamQuestions::EXAM_SUBJECTS        # 3과목 기준 모의고사 카드
      @curriculum_subjects = ExamCurriculum::SUBJECTS      # 챕터별 풀기 (4권 유지)
      @total_count = ExamQuestions.count                   # 뷰에서 반복 호출 방지

      # 정적 콘텐츠이므로 HTTP 캐싱
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "모의고사",
        description: "공공조달관리사 4지선다 모의고사. 3과목별·전체 #{@total_count}문제, 즉시 채점·상세 해설 제공.",
        keywords: "공공조달관리사 모의고사, 공공조달 시험 문제, 국가기술자격 모의고사",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    # GET /quiz/simulation — 실전 시험 모드 (120분 타이머 + 3과목 80문제 + 일괄채점)
    def simulation
      # 3과목 기준 80문제 샘플링 (사전 슬라이싱된 데이터 사용)
      q1 = ExamQuestions.sliced_by_subject(1).sample(30)
      q2 = ExamQuestions.sliced_by_subject(2).sample(20)
      q3_4 = ExamQuestions.sliced_by_subject(3) + ExamQuestions.sliced_by_subject(4)
      q3 = q3_4.sample(30)
      @questions = (q1 + q2 + q3).shuffle

      set_meta_tags(
        title: "실전 시험 모드",
        description: "공공조달관리사 실전 시험 모드 — 3과목 80문제 120분 타이머. 실제 시험과 동일한 환경으로 도전하세요.",
        keywords: "공공조달관리사 실전 시험, 공공조달 모의고사 타이머",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    # GET /quiz/analysis — 학습 분석 대시보드
    def analysis
      # 정적 페이지 (JS가 localStorage에서 데이터 로드)
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "학습 분석 대시보드",
        description: "과목별 챕터 진도, 모의고사 점수, 오답 분포를 한눈에 확인하세요. 공공조달관리사 합격을 위한 맞춤 학습 추천.",
        keywords: "공공조달관리사 학습 분석, 공공조달 오답 분석, 시험 대비 학습 추적",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    # GET /quiz/bookmarks — 북마크 문제 (모든 문제를 내려보내고 클라이언트에서 필터)
    def bookmarks
      @all_questions = ExamQuestions.all_sliced_with_difficulty
      @chapter_map = ExamCurriculum.chapter_map

      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "북마크 문제",
        description: "별표로 저장한 문제만 모아서 풀어보는 북마크 노트. 중요 문제를 반복 학습하여 완벽하게 정복하세요.",
        keywords: "공공조달관리사 북마크, 문제 저장, 중요 문제 복습",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    # GET /quiz/wrong — 오답 노트 재풀이 (모든 문제를 내려보내고 클라이언트에서 필터)
    def wrong
      @all_questions = ExamQuestions.all_sliced_with_difficulty
      @chapter_map = ExamCurriculum.chapter_map

      # 문제 데이터가 변경되지 않으므로 HTTP 캐싱
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day

      set_meta_tags(
        title: "오답 노트",
        description: "틀렸던 문제만 다시 풀어보는 오답 노트. 공공조달관리사 모의고사 오답을 반복 학습하여 완벽하게 정복하세요.",
        keywords: "공공조달관리사 오답노트, 오답 복습, 공공조달 시험",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    # GET /quiz/subject/:subject_id/chapter/:chapter_num — 챕터별 문제 풀기
    def chapter
      @subject = ExamCurriculum.find_subject(params[:subject_id])
      return redirect_to exam_quiz_index_path, alert: "존재하지 않는 과목입니다." unless @subject

      @chapter_num = params[:chapter_num].to_i
      @chapter = ExamCurriculum.find_chapter(params[:subject_id], params[:chapter_num])
      return redirect_to exam_subject_path(@subject[:id]), alert: "존재하지 않는 챕터입니다." unless @chapter

      # 사전 슬라이싱+난이도 포함된 데이터 사용
      @questions = ExamQuestions.sliced_by_chapter(@subject[:id], @chapter_num)
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
          type: "website",
          image: "https://exam.silmu.kr/icon.png"
        },
        twitter: { card: "summary" }
      )

      render :show
    end

    # GET /quiz/:id — 실제 퀴즈 (id: 1~3 = 시험 과목별, 'all' = 전체)
    def show
      @subject_id = params[:id]

      if @subject_id == "all"
        @questions = ExamQuestions.all_sliced_with_difficulty
        @quiz_title = "전체 모의고사"
        @quiz_subtitle = "3과목 전체 — #{@questions.size}문제"
        @subject = nil
        @color = "blue"
      else
        exam_subject_id = @subject_id.to_i
        @subject = ExamQuestions::EXAM_SUBJECTS.find { |s| s[:id] == exam_subject_id }
        return redirect_to exam_quiz_index_path, alert: "존재하지 않는 과목입니다." unless @subject

        # 시험 과목 기준 슬라이싱 데이터 (3과목 매핑: subject_ids로 합산)
        @questions = @subject[:subject_ids].flat_map { |sid| ExamQuestions.sliced_by_subject(sid) }
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
          type: "website",
          image: "https://exam.silmu.kr/icon.png"
        },
        twitter: { card: "summary" }
      )
    end
  end
end
