class ProjectPlansController < ApplicationController
  def index
    set_meta_tags(
      title: "사업계획서 생성기",
      description: "수의계약 사업계획서를 간편하게 작성합니다. 사업명, 필요성, 예산 등을 입력하면 공문 서식의 사업계획서를 자동 생성.",
      keywords: "사업계획서, 수의계약, 사업계획 수립, 공문 서식",
      og: { title: "사업계획서 생성기 — 실무.kr", url: canonical_url }
    )
  end
end
