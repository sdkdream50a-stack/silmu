class ContractReasonsController < ApplicationController
  def index
    set_meta_tags(
      title: "수의계약 사유서 생성기",
      description: "수의계약 사유서를 간편하게 작성합니다. 계약구분, 사유를 선택하면 법적 근거가 자동 삽입된 사유서를 생성.",
      keywords: "수의계약 사유서, 수의계약 요청서, 법적 근거, 지방계약법",
      og: { title: "수의계약 사유서 생성기 — 실무.kr", url: canonical_url }
    )
  end
end
