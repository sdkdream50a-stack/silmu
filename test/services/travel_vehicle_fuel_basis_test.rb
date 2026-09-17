# frozen_string_literal: true

require "test_helper"

# 자가용 출장 연료비 근거 정정 회귀 (2026-09-17). 원문: 공무원 여비 규정 별표 2(2026.6.30.) 비고 제4호.
class TravelVehicleFuelBasisTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917235000_travel_vehicle_fuel_basis.rb")

  setup do
    body = [ "#### 자가용 이용 여비 지급 기준 (공무원 여비규정 제18조)", "| 연료비 | 실제 주행거리 × 유가 기준 단가 (재정경제부 고시) |",
             "| 통행료 | 실비 지급 (영수증 첨부) |", "| 일비 | 해당 직급 일비 기준 100% |", "| 식비 | 해당 직급 식비 기준 100% |",
             "연료비 지급 단위는 km당 일정 금액으로 산정하며, 기획재정부가 분기마다 유류비 기준단가를 고시합니다." ].join("\n")
    Topic.new(slug: "vehicle-travel-allowance", name: "자가용", category: "travel", sector: "common", regulation_content: body).save!(validate: false)
    Guide.new(slug: "travel-expense-complete-10", title: "여비 10", sections: { "laws" => [ { "name" => "기획재정부 여비 관련 유권해석" } ] }).save!(validate: false)
  end

  def text = Topic.find_by!(slug: "vehicle-travel-allowance").regulation_content

  test "NORMAL: 연료비 기준은 인사혁신처장이 기획예산처장관과 협의 (별표 2 비고 4)" do
    capture_io { load MIGRATION }
    assert_includes text, "인사혁신처장이 기획예산처장관과 협의"
    assert_not_includes text, "고시"
  end

  test "EDGE: 근거 조문이 제18조가 아니라 별표 2 비고 제4호" do
    capture_io { load MIGRATION }
    assert_includes text, "별표 2 비고 제4호"
    assert_not_includes text, "제18조"
  end

  test "LOWER_BOUND: 통행료 행과 가이드 라벨" do
    capture_io { load MIGRATION }
    assert_includes text, "| 통행료 | 실비 지급 (영수증 첨부) |"
    assert_not_includes Guide.find_by!(slug: "travel-expense-complete-10").sections.to_json, "기획재정부"
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: missing text aborts" do
    Topic.find_by!(slug: "vehicle-travel-allowance").update_columns(regulation_content: "고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
  end
end
