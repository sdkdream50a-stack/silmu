class ToolsController < ApplicationController
  def index
    set_meta_tags(
      title: "실무 도구",
      description: "계약방식 결정, 예정가격 계산, 계약보증금 계산, 여비계산 등 공무원 업무를 자동화하는 14개 도구.",
      keywords: "계약방식, 예정가격 계산기, 계약보증금, 여비계산기, 법정기간, PDF 도구",
      og: { title: "실무 도구 — 실무", url: request.original_url }
    )
  end

  def travel_calculator
    set_meta_tags(
      title: "여비계산기",
      description: "공무원 국내·외 출장 여비를 자동으로 계산합니다. 교통비, 일비, 숙박비, 식비를 한 번에 산출.",
      keywords: "여비계산기, 출장 여비, 공무원 출장비, 교통비, 숙박비",
      og: { title: "여비계산기 — 실무", url: request.original_url }
    )
  end
end
