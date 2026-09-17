# frozen_string_literal: true

require "test_helper"

# 계약보증금 면제 사유는 시행령 제53조제1항 네 가지뿐이다 (2026-09-17 전수감사 G-49).
class AuditCaseGuaranteePremiseTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918130000_auditcase_guarantee_exemption_premise.rb")

  def seed_pg(detail: "| 신용등급 기준 | 국내 신용평가기관 BBB 이상 |")
    AuditCase.create!(title: "이행보증금", slug: "performance-guarantee-waiver-loss", issue: "직전 2회 이상 성실 이행, 신용등급 BBB 이상",
                      category: "contract", detail: detail, checkpoints: "[\"신용등급: 신용평가서(BBB 이상)\"]")
  end

  test "NORMAL: 창작 면제 요건(신용등급·성실이행)을 원문 네 가지 사유와 확약서로 교체한다" do
    ac = seed_pg
    capture_io { load MIGRATION }
    ac.reload
    assert_not_includes [ ac.issue, ac.detail, ac.lesson, ac.checkpoints.to_s ].join, "BBB"
    assert_includes ac.detail, "계약금액이 5천만원 이하인 계약"
    assert_includes ac.lesson, "확약서"
    assert_includes ac.detail, "| **합계** | **7,200만원** |"
  end

  test "EDGE: 공사 1억원 면제 전제를 계약 종류 무관 5천만원으로 정정한다" do
    ac = AuditCase.create!(title: "면제", slug: "contract-guarantee-exemption-wrong", category: "contract",
                           issue: "계약금액 8,000만원 물품 계약에서 계약보증금을 면제함. 물품의 경우 계약금액 5,000만원 이하만 면제 가능하나, 담당자가 면제 기준금액을 혼동하여 잘못 면제 처리한 사례.")
    capture_io { load MIGRATION }
    assert_includes ac.reload.issue, "계약 종류와 관계없이 계약금액 5,000만원 이하"
  end

  test "LOWER_BOUND: 재실행하면 0건" do
    seed_pg
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "UPPER_BOUND: DRY_RUN 은 세지만 쓰지 않는다" do
    ac = seed_pg
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=1/, out)
    assert_includes ac.reload.detail, "BBB"
  ensure
    ENV.delete("DRY_RUN")
  end

  test "EXCEPTION: 이전 본문 지문이 없으면 교체하지 않고 롤백한다" do
    ac = seed_pg(detail: "다른 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal "다른 본문", ac.reload.detail
  end
end
