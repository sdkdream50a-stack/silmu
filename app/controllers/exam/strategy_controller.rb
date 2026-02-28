module Exam
  class StrategyController < ApplicationController
    layout 'exam'

    def index
      set_meta_tags(
        title: '합격 전략 — 과목별 학습법·출제 유형·합격 수기',
        description: '공공조달관리사 합격자들의 실제 학습 전략을 공개합니다. 4과목 핵심 학습법, 자주 출제되는 유형, 합격 수기까지 한곳에.',
        keywords: '공공조달관리사 합격 전략, 공공조달관리사 학습법, 공공조달관리사 합격 수기, 시험 출제 유형',
        og: {
          title: '공공조달관리사 합격 전략 · 학습법 · 수기',
          description: '합격자들의 실제 전략을 기반으로 한 과목별 학습법과 출제 유형 분석',
          url: 'https://exam.silmu.kr/exam-strategy'
        },
        canonical: 'https://exam.silmu.kr/exam-strategy'
      )
    end
  end
end
