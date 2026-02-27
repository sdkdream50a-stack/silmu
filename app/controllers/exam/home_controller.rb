class Exam::HomeController < ApplicationController
  layout 'exam'

  def index
    set_meta_tags(
      title: "공공조달관리사 시험 대비",
      description: "2026년 신설 공공조달관리사 국가기술자격 시험 대비. 법령 핵심 정리, 감사사례, 실무 도구 제공.",
      keywords: "공공조달관리사, 국가자격시험, 공공조달, 계약 실무, 시험 대비, 2026",
      canonical: "https://exam.silmu.kr",
      og: {
        title: "공공조달관리사 시험 대비 | 실무.kr",
        description: "2026년 신설 공공조달관리사 국가기술자격 시험 대비. 법령 핵심 정리, 감사사례, 실무 도구 제공.",
        url: "https://exam.silmu.kr",
        type: "website"
      }
    )
  end
end
