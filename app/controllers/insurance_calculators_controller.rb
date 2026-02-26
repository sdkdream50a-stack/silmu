# 4대보험 정산보험료 계산기 컨트롤러
class InsuranceCalculatorsController < ApplicationController
  def index
    set_meta_tags(
      title: "4대보험 정산보험료 계산기 — 연말·퇴직정산 자동 계산",
      description: "국민연금·건강보험·요양보험·고용보험·산재보험 정산보험료를 자동으로 계산합니다. 연말정산·퇴직정산 구분 계산, 기납보험료 대비 추가납부·환급액까지 한 번에 확인하세요.",
      keywords: "4대보험, 정산보험료, 건강보험 정산, 고용보험 정산, 연말정산, 퇴직정산, 공무원",
      og: { title: "4대보험 정산보험료 계산기 — 실무.kr", url: canonical_url }
    )
  end
end
