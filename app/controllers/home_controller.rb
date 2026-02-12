class HomeController < ApplicationController
  def index
    set_meta_tags(
      title: "계약 실무, 이제 혼자 고민하지 마세요",
      description: "공무원을 위한 계약 실무 가이드 — 수의계약, 입찰, 검수, 예산 업무를 쉽고 정확하게. 16개 자동화 도구와 25개 법령 가이드 제공.",
      keywords: "공무원, 계약 실무, 수의계약, 입찰, 검수, 예산, 실무 도구",
      og: { title: "실무.kr — 공무원 계약 실무 가이드", url: canonical_url }
    )
  end

  def about
    set_meta_tags(
      title: "서비스 소개",
      description: "실무(silmu.kr)는 공무원의 계약·예산 업무를 돕는 무료 서비스입니다. 법령 가이드, 자동화 도구, 문서 양식을 제공합니다.",
      og: { title: "실무.kr 서비스 소개", url: canonical_url }
    )
  end

  def privacy
    set_meta_tags(
      title: "개인정보처리방침",
      description: "실무(silmu.kr) 개인정보처리방침입니다.",
      og: { title: "실무.kr 개인정보처리방침", url: canonical_url }
    )
  end

  def terms
    set_meta_tags(
      title: "이용약관",
      description: "실무(silmu.kr) 서비스 이용약관입니다.",
      og: { title: "실무.kr 이용약관", url: canonical_url }
    )
  end
end
