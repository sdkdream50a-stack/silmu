# frozen_string_literal: true

require "test_helper"

# 연수 시연 fixture — 심어 둔 오류와 검사 결과가 **정확히** 같아야 한다(못 잡음·거짓 경보 모두 실패).
class ReviewLab::DemoExpectedFindingsTest < ActiveSupport::TestCase
  D = ReviewLab::Demo

  test "견적서 demo = 기대표와 정확히 일치" do
    c = D.compare(D.run_quote, D::QUOTE_EXPECTED)
    assert c[:ok], "missing=#{c[:missing]} extra=#{c[:extra]}"
  end

  test "공고 패키지 demo = 기대표와 정확히 일치" do
    c = D.compare(D.run_package, D::PACKAGE_EXPECTED)
    assert c[:ok], "missing=#{c[:missing]} extra=#{c[:extra]}"
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
