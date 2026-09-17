# frozen_string_literal: true

require "test_helper"

# 감사사례 조문 인용 정정 1차 (2026-09-17 전수감사 G-48) — 원문으로 확정된 조문만 바꾸고, 대체 조문이 없으면 삭제한다.
class AuditCaseCitationBatch1Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918120000_auditcase_citation_batch1.rb")

  def seed(slug, **fields)
    AuditCase.create!({ title: slug, slug: slug, issue: "○○", category: "contract" }.merge(fields))
  end

  test "NORMAL: 목적 외 사용 벌칙 조문 §40 → §41" do
    ac = seed("national-subsidy-purpose-misuse", legal_basis: "보조금 관리에 관한 법률 제22조(용도 외 사용 금지), 제40조(벌칙)",
                                             detail: "| 형사 고발 | 보조금법 제40조 위반 (수사 중) |")
    capture_io { load MIGRATION }
    assert_includes ac.reload.legal_basis, "제41조(벌칙)"
    assert_not_includes ac.legal_basis, "제40조"
  end

  test "EDGE: 없는 법령 «지방공무원 여비규정» 인용은 대체명 없이 삭제한다" do
    ac = seed("vehicle-travel-allowance-distance-fraud", legal_basis: "공무원 여비 규정 제13조, 지방공무원 여비규정 자동차운임 동일 조문",
                                                     detail: "공무원 여비 규정 제13조 및 지방공무원 여비규정 제13조·별표 2(자동차운임)에 따라")
    capture_io { load MIGRATION }
    assert_equal "공무원 여비 규정 제13조", ac.reload.legal_basis
    assert_equal "공무원 여비 규정 제13조에 따라", ac.detail
  end

  test "LOWER_BOUND: 두 번 실행해도 두 번째는 0건" do
    seed("information-disclosure-delay", detail: "공공기관의 정보공개에 관한 법률 제11조 제3항은 비공개 결정 시 이유를 밝혀야 한다.")
    out1, = capture_io { load MIGRATION }
    out2, = capture_io { load MIGRATION }
    assert_match(/changes=1 /, out1)
    assert_match(/changes=0 /, out2)
  end

  test "UPPER_BOUND: 없는 행은 건너뛰고 missing 으로 센다" do
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0 missing=\d+/, out)
    assert_no_match(/missing=0\b/, out)
  end

  test "EXCEPTION: 지문이 어긋나면 전체 롤백" do
    ok = seed("national-subsidy-purpose-misuse", legal_basis: "보조금 관리에 관한 법률 제22조(용도 외 사용 금지), 제40조(벌칙)",
                                             detail: "| 형사 고발 | 보조금법 제40조 위반 (수사 중) |")
    seed("information-disclosure-delay", detail: "정보공개법 제13조 제5항")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes ok.reload.legal_basis, "제40조(벌칙)"
  end
end
