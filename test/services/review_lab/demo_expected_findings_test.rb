# frozen_string_literal: true

require "test_helper"

# 연수 시연 fixture — 심어 둔 오류와 검사 결과가 **정확히** 같아야 한다(못 잡음·거짓 경보 모두 실패).
class ReviewLab::DemoExpectedFindingsTest < ActiveSupport::TestCase
  D = ReviewLab::Demo
  B = ReviewLab::FixtureBuilder

  test "견적서 demo = 기대표와 정확히 일치" do
    c = D.compare(D.run_quote, D::QUOTE_EXPECTED)
    assert c[:ok], "missing=#{c[:missing]} extra=#{c[:extra]}"
  end

  test "공고 패키지 demo = 기대표와 정확히 일치" do
    c = D.compare(D.run_package, D::PACKAGE_EXPECTED)
    assert c[:ok], "missing=#{c[:missing]} extra=#{c[:extra]}"
  end

  # ── P4 예산문서 demo ─────────────────────────────────────────────
  test "사업계획·산출기초 demo = 기대표와 정확히 일치" do
    c = D.compare(D.run_budget, D::BUDGET_EXPECTED)
    assert c[:ok], "missing=#{c[:missing]} extra=#{c[:extra]}"
  end

  test "음성 대조 — 산출기초의 심은 행 오류를 고치면 B-ROW BLOCK 이 사라지고 나머지는 그대로다" do
    rows = D.cost_basis_rows.map { |r| r[1] == "서가" ? r.dup.tap { |x| x[6] = 2_280_000 } : r }
    b = ReviewLab::TextExtractor.call(bytes: B.xlsx(rows), role: "cost_basis", label: "산출기초")
    r = ReviewLab::BudgetReviewer.call(documents: [ D.budget_documents.first, b ])
    refute(r.findings.any? { |f| f.code == "B-ROW" && f.severity == "BLOCK" })
    # 고친 행 때문에 «적힌 공급가액» 과 품목 합이 어긋나므로 B-SUM 은 이제 BLOCK 이어야 한다 —
    # 한 곳을 고치면 다른 모순이 드러나는 것이 정상이다(조용히 전부 PASS 가 되면 검사기가 죽은 것).
    assert(r.findings.any? { |f| f.code == "B-SUM" && f.severity == "BLOCK" })
  end

  test "음성 대조 — 두 문서 금액을 맞추면 B-CROSS-TOTAL 이 PASS 로 뒤집힌다" do
    blocks = D.project_plan_blocks.map { |x| x.is_a?(Array) && x[0] == "총사업비" ? [ "총사업비", "7,788,000원" ] : x }
    p_doc = ReviewLab::TextExtractor.call(bytes: B.hwpx(blocks), role: "project_plan", label: "사업계획서")
    r = ReviewLab::BudgetReviewer.call(documents: [ p_doc, D.budget_documents.last ])
    assert_equal [ "PASS" ], r.findings.select { |f| f.code == "B-CROSS-TOTAL" }.map(&:severity)
  end

  test "예산 demo 문서에 실재 개인정보가 없다 — 가상 표기만" do
    docs = D.budget_documents
    assert(docs.all?(&:ok?))
    text = docs.map(&:full_text).join("\n")
    assert_includes text, "가상초등학교"
    assert_empty ReviewLab::PiiScanner.scan(docs.first) + ReviewLab::PiiScanner.scan(docs.last)
  end

  test "demo 는 실제 파일 경로를 탄다 — 4개 포맷 모두 파서를 통과" do
    formats = (D.quote_documents + D.package_documents).map(&:format).uniq.sort
    assert_equal %i[docx hwpx pdf xlsx], formats
    assert((D.quote_documents + D.package_documents).all?(&:ok?))
  end

  test "음성 대조 — 기대표에서 한 줄을 빼면 «더 나옴» 으로, 한 줄을 더하면 «못 찾음» 으로 실패한다" do
    review = D.run_quote
    refute D.compare(review, D::QUOTE_EXPECTED.drop(1))[:ok]
    refute D.compare(review, D::QUOTE_EXPECTED + [ [ "Q-DUP", "WARN", "없는 오류" ] ])[:ok]
  end

  test "음성 대조 — 심어 둔 오류를 고친 견적서에서는 해당 finding 이 사라진다" do
    rows = D.quote_rows.map { |r| r[1] == "학생용 책상" ? r.dup.tap { |x| x[6] = 2_460_000 } : r }
    doc = ReviewLab::TextExtractor.call(bytes: ReviewLab::FixtureBuilder.xlsx(rows), role: "quote", label: "견적서")
    r = ReviewLab::QuoteReviewer.call(documents: [ doc ], today: D::QUOTE_TODAY, **D::QUOTE_OPTIONS)
    refute(r.findings.any? { |f| f.code == "Q-ROW" && f.severity == "BLOCK" })
  end

  test "가상 문서에 실재 식별정보가 없다 — 가상 표기와 불가능한 번호만 쓴다" do
    text = (D.quote_documents + D.package_documents).map(&:full_text).join("\n")
    assert_includes text, "000-00-00000"
    assert_includes text, "02-000-0000"
    refute_match(/01[016789]-?\d{3,4}-?\d{4}/, text)
    assert_empty ReviewLab::PiiScanner.scan(ReviewLab::DocumentArtifact.new(role: "other", label: "x", format: :docx,
                                                                            segments: [ { text: text, locator: "-" } ]))
  end
end
