class GuidesController < ApplicationController
  def index
  end

  def show
  end

  # 계약 흐름도 페이지
  def contract_flow
  end

  # 계약업무 사전 체크리스트
  def pre_contract_checklist
  end

  # 자료실/FAQ
  def resources
    @resources = [
      { id: 1, title: "입찰자격제한 처분 관련 대법원 판례 해설", category: "판례", date: "2026.01.28", type: "판례해설" },
      { id: 2, title: "수의계약 체결 시 주의사항 FAQ", category: "FAQ", date: "2026.01.25", type: "FAQ" },
      { id: 3, title: "2026년 계약집행 특례 안내", category: "공지", date: "2026.01.20", type: "공지사항" },
      { id: 4, title: "부정당업자 제재 절차 안내", category: "FAQ", date: "2026.01.18", type: "FAQ" },
      { id: 5, title: "분할계약 금지 관련 유권해석", category: "판례", date: "2026.01.15", type: "유권해석" },
    ]
  end
end
