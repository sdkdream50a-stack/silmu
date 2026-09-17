# frozen_string_literal: true

require "test_helper"

# 학교회계 조문 정정 migration 회귀 (2026-09-17 G-28). 원문: 초·중등교육법 제30조의2·3 [시행 2026.9.11.].
class SchoolAccountingLawCorrectionTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917140000_school_accounting_law_correction.rb")

  setup do
    @topic = Topic.new(
      slug: "school-budget-compilation", name: "학교회계 예산편성 절차", category: "budget", sector: "edu",
      summary: "초중등교육법 제30조의2~30조의4에 근거하며, 지방자치단체 예산과는 다릅니다.",
      law_content: "### 초중등교육법 제30조의3 (학교회계의 세입)\n6. 학교기업의 수입",
      decree_content: "### 제64조(학교회계의 예산 편성)\n① 가짜",
      rule_content: "### 제9조의2(학교회계 세출예산 과목 구분)\n① 가짜",
      interpretation_content: "[회신] 가짜 (교육부 학교정책과 유권해석)",
      regulation_content: "「초중등교육법」 제30조의2, 동법 시행령 제64조, 및 지침",
      practical_tips: "- 근거 법령: 초·중등교육법 제30조의2, 동법 시행령 제60조\n- **11월**: 학교운영위원회 예산안 심의\n- **12월**: 교장 예산 확정\n- **1월 31일까지**: 다음연도 예산 최종 확정·공개",
      qa_content: "계속비 사업 관련 예산은 명시이월, 부득이한 사유로 집행하지 못한 경우는 사고이월이 가능합니다.",
      flowchart_mermaid: "C[11월\n학교운영위원회 심의] G[12월\n교장 예산 확정] H[1월 31일까지\n예산 공개\n학교 홈페이지] L[2월 말\n결산 완료]",
      quick_stats: [
        { "label" => "회계연도", "note" => "초중등교육법 제30조의2 제3항(지자체와 상이)" },
        { "label" => "예산안 제출", "note" => "학교운영위원회 심의" },
        { "label" => "결산 제출", "note" => "초중등교육법 제30조의2 제5항", "value" => "다음 회계연도 3월 31일 이전 교육감 제출" }
      ],
      faqs: [
        { "answer" => "2월 말일에 끝납니다(초중등교육법 제30조의2)." },
        { "answer" => "운영위원회의 심의를 거쳐 학교장이 확정하고 교육감에게 제출합니다. 심의 없이 예산을 집행하면 위법이며, 확정권은 학교장" },
        { "answer" => "학교발전기금 전입금, 국가·지자체 보조금, 학교 운영 수입(시설 임대·이자) 등으로 구성됩니다(초중등교육법 제30조의3)." }
      ]
    )
    @topic.save!(validate: false)
    base = { category: "회계", severity: "보통", issue: "지적", published: true, sector: :edu }
    @card = AuditCase.create!(base.merge(title: "카드", slug: "goe-2021-credit-card-payment-account",
      lesson: "회계연도 종료 직전 미입금 카드대금은 반드시 당해 회계연도 결산에 포함하거나 명시이월 결재를 거쳐야 하며, 소급 처리는 안 됩니다."))
    @pension = AuditCase.create!(base.merge(title: "퇴직연금", slug: "goe-2021-retirement-pension-mismanagement",
      lesson: "부족 시 **즉시 추가 적립분을 세출예산에 추경 또는 명시이월 처리**로 보전하세요. 운용기관과 협의해 적립금 즉시 보충이 안 되면, 학교회계 일시 차입금으로 우선 지급 후 차기 회계연도에 보전하는 방식이 가능합니다. 다만 차입금 처리는 학교운영위 심의를 거쳐야 합니다."))
    @deadline = AuditCase.create!(base.merge(title: "기한", slug: "school-budget-deadline-violation",
      legal_basis: "초·중등교육법 제30조의3(학교회계의 운영), 초·중등교육법 시행령 제64조(학교회계의 운영), 공립학교 회계규칙",
      lesson: "- 1월 말: 예산안 완성\n- 2월 중: 운영위원회 심의·의결"))
  end

  test "NORMAL: fabricated statute fields are replaced with the verbatim articles" do
    capture_io { load MIGRATION }
    @topic.reload
    assert_includes @topic.law_content, "회계연도가 끝난 후 2개월 이내에 학교운영위원회에 제출하여야 한다."
    assert_not_includes @topic.law_content, "학교기업의 수입"
    assert_not_includes @topic.decree_content, "제64조(학교회계의 예산 편성)"
    assert_includes @topic.decree_content, "제64조(학교발전기금)"
    assert_not_includes @topic.rule_content, "제9조의2"
    assert_not_includes @topic.interpretation_content, "학교정책과 유권해석"
  end

  test "EDGE: jsonb citations point at 제30조의3 and the settlement goes to the committee" do
    capture_io { load MIGRATION }
    @topic.reload
    stats = @topic.quick_stats.to_json
    assert_includes stats, "제30조의3①"
    assert_includes stats, "회계연도 종료 후 2개월 이내 학교운영위원회 제출"
    assert_not_includes stats, "교육감 제출"
    faqs = @topic.faqs.to_json
    assert_includes faqs, "제30조의2②"
    assert_not_includes faqs, "학교 운영 수입"
  end

  test "LOWER_BOUND: audit cases lose the 명시이월 결재 / 일시 차입 mixing" do
    capture_io { load MIGRATION }
    assert_not_includes @card.reload.lesson, "명시이월 결재"
    assert_includes @card.lesson, "3.1.~2월 말일"
    assert_not_includes @pension.reload.lesson, "일시 차입금으로 우선 지급"
    assert_not_includes @deadline.reload.legal_basis, "시행령 제64조"
    assert_includes @deadline.lesson, "제30조의3③"
  end

  test "UPPER_BOUND: a second run changes nothing" do
    capture_io { load MIGRATION }
    snapshot = [ @topic.reload.attributes.except("updated_at"), @pension.reload.lesson ]
    out, = capture_io { load MIGRATION }
    assert_equal snapshot, [ @topic.reload.attributes.except("updated_at"), @pension.reload.lesson ]
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: DRY_RUN writes nothing and counts every change" do
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=24/, out)
    assert_includes @topic.reload.decree_content, "제64조(학교회계의 예산 편성)"
  ensure
    ENV.delete("DRY_RUN")
  end
end
