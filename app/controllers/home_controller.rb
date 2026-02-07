class HomeController < ApplicationController
  def index
    set_meta_tags(
      title: "감사 걱정 없는, 퇴근 있는, 은퇴 준비되는 공무원",
      description: "공무원을 위한 계약 실무 가이드 — 수의계약, 입찰, 검수, 예산 업무를 쉽고 정확하게. 14개 자동화 도구와 20개 업무 가이드 제공.",
      keywords: "공무원, 계약 실무, 수의계약, 입찰, 검수, 예산, 실무 도구",
      og: { title: "실무 — 공무원 계약 실무 가이드", url: request.original_url }
    )
  end

  def about
    set_meta_tags(
      title: "서비스 소개",
      description: "실무(silmu.kr)는 공무원의 계약·예산 업무를 돕는 무료 서비스입니다. 법령 가이드, 자동화 도구, 문서 양식을 제공합니다.",
      og: { title: "실무 서비스 소개", url: request.original_url }
    )
  end
end
