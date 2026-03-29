module Exam
  class PracticalController < ApplicationController
    layout "exam"

    def index
      @questions = ExamPracticalQuestions::QUESTIONS
      @categories = ExamPracticalQuestions::CATEGORIES
      @total_points = ExamPracticalQuestions.total_points
      expires_in 1.day, public: true
      set_meta_tags(
        title: "실기 대비 — 필답형 예상문제 30선",
        description: "공공조달관리사 실기 시험(PBT 필답형 150분) 예상문제 30선 + 모범 답안. 카테고리별 분류로 취약 영역을 집중 학습하세요.",
        keywords: "공공조달관리사 실기, 필답형 시험, 공공조달 서술형",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end
  end
end
