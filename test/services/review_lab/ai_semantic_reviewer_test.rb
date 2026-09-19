# frozen_string_literal: true

require "test_helper"

# AI 의미검사 — AI 결과를 FACT 로 승격하지 않고, 원문에 없는 인용은 버리고, 보내기 전에 가린다.
class ReviewLab::AiSemanticReviewerTest < ActiveSupport::TestCase
  def doc(*paras) = ReviewLab::TextExtractor.call(bytes: ReviewLab::FixtureBuilder.docx(paras), role: "task_order", label: "과업지시서")

  test "원문에 있는 인용은 CHECK finding 이 되고, 없는 인용(환각)은 버린다" do
    reply = { issues: [
      { document: "과업지시서", quote: "설치 범위는 협의하여 결정한다", type: "ambiguous", explanation: "기준 없음", check: "범위를 적으세요" },
      { document: "과업지시서", quote: "이 문장은 문서에 없다", type: "conflict", explanation: "x", check: "y" }
    ] }.to_json
    r = ReviewLab::AiSemanticReviewer.call(documents: [ doc("가. 설치 범위는 협의하여 결정한다.") ], http: ->(_p) { reply })
    assert_equal 1, r.findings.size
    assert_equal 1, r.dropped
    f = r.findings.first
    assert_equal "CHECK", f.severity
    assert f.ai?
    assert_equal "AI 검토 · 추가 확인 필요", f.origin_label
  end

  test "AI 가 BLOCK 을 주장해도 Finding 은 CHECK 로 고정된다" do
    f = ReviewLab::Finding.new(severity: "BLOCK", code: "AI-X", problem: "p", origin: :ai)
    assert_equal "CHECK", f.severity
    assert_equal "CHECK", ReviewLab::Finding.new(severity: "PASS", code: "AI-X", problem: "p", origin: :ai).severity
    assert_equal "BLOCK", ReviewLab::Finding.new(severity: "BLOCK", code: "R", problem: "p").severity, "규칙 finding 은 그대로(대조)"
  end

  test "보내는 본문에서 개인정보 형태를 가린다" do
    sent = nil
    ReviewLab::AiSemanticReviewer.call(documents: [ doc("담당 010-1234-5678 · 900101-1234567 · a@b.kr") ],
                                       http: ->(p) { sent = p; { issues: [] }.to_json })
    refute_includes sent, "1234-5678"
    refute_includes sent, "900101-1234567"
    refute_includes sent, "a@b.kr"
    assert_includes sent, ReviewLab::PiiScanner::MASK
  end

  test "응답을 해석 못 하면 결과 0건 + 이유 — 규칙 검사를 막지 않는다" do
    r = ReviewLab::AiSemanticReviewer.call(documents: [ doc("가. 문장") ], http: ->(_p) { "죄송합니다" })
    assert_empty r.findings
    assert r.error.present?
  end

  test "키가 없으면 호출하지 않는다" do
    old = ENV.delete("ANTHROPIC_API_KEY")
    r = ReviewLab::AiSemanticReviewer.call(documents: [ doc("가. 문장") ])
    assert_empty r.findings
    assert_match(/키/, r.error)
  ensure
    ENV["ANTHROPIC_API_KEY"] = old if old
  end
end
