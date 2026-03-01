module Exam
  class ExamInfoController < ApplicationController
    layout 'exam'

    def index
      # 정적 콘텐츠이므로 HTTP 캐싱
      expires_in 1.day, public: true, stale_while_revalidate: 7.days

      set_meta_tags(
        title: '공공조달관리사 시험 정보 — 응시자격·일정·과목·합격기준',
        description: '2026년 신설 공공조달관리사 국가기술자격 시험의 응시자격, 시험 일정, 과목 구성, 합격 기준, 접수 방법을 안내합니다.',
        keywords: '공공조달관리사, 시험 일정, 응시자격, 합격기준, 시험 과목, 국가기술자격, 공공조달 자격증',
        og: {
          title: '공공조달관리사 시험 정보',
          description: '2026년 첫 시험 — 응시자격·일정·과목·합격기준 완벽 정리',
          url: 'https://exam.silmu.kr/exam-info'
        },
        canonical: 'https://exam.silmu.kr/exam-info'
      )
    end
  end
end
