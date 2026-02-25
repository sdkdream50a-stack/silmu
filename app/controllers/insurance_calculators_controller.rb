# 4대보험 정산보험료 계산기 컨트롤러
class InsuranceCalculatorsController < ApplicationController
  def index
    set_meta_tags(
      title: "4대보험 정산보험료 계산기",
      description: "국민연금·건강·요양·고용·산재보험 정산보험료를 자동 계산합니다. 연말정산·퇴직정산·합산까지 한 번에 처리하세요.",
      keywords: "4대보험, 정산보험료, 건강보험 정산, 고용보험 정산, 연말정산, 퇴직정산, 공무원",
      og: { title: "4대보험 정산보험료 계산기 — 실무.kr", url: canonical_url }
    )
  end
end
