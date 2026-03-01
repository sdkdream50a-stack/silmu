module Exam
  class StrategyController < ApplicationController
    layout 'exam'

    def index
      # 정적 콘텐츠이므로 HTTP 캐싱
      expires_in 1.day, public: true, stale_while_revalidate: 7.days

      set_meta_tags(
        title: '합격 전략 — 과목별 학습법·출제 유형·학습 루틴',
        description: '공공조달관리사 1회 시험 대비 전략. 4과목 핵심 학습법, 자주 출제되는 유형, 3개월 학습 루틴을 안내합니다.',
        keywords: '공공조달관리사 합격 전략, 공공조달관리사 학습법, 공공조달관리사 시험 준비, 시험 출제 유형',
        og: {
          title: '공공조달관리사 합격 전략 · 과목별 학습법 · 출제 유형',
          description: '4과목 핵심 학습법과 출제 유형 분석으로 1회 시험 합격을 준비하세요',
          url: 'https://exam.silmu.kr/exam-strategy'
        },
        canonical: 'https://exam.silmu.kr/exam-strategy'
      )
    end
  end
end
