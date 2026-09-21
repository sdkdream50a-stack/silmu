# frozen_string_literal: true

require "test_helper"

# 「초·중등교육법」 제32조제1항 호 번호 (법제처 lsiSeq=283903, 2026.9.11. 시행 원문에서 고정 — 구현 문자열을 읽어 오지 않는다).
class AuditCaseBudgetCommitteeClauseTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260921120000_auditcase_budget_committee_clause_numbers.rb")
  SEED = Rails.root.join("db/seeds/audit_cases/budget_compilation_audit_cases.rb")
  SLUG = "school-budget-without-committee-review"

  # 원문 호 번호 → 그 호의 핵심어. 표·본문이 이 핵심어를 다른 호 번호에 붙이면 실패한다.
  OFFICIAL = { 1 => "학칙", 2 => "예산안", 3 => "교육과정", 10 => "급식", 12 => "운동부" }.freeze

  PROD_DETAIL = <<~MD
    ### 초·중등교육법상 학교운영위원회 심의 사항

    | 초·중등교육법 제32조 | 주요 심의 사항 |
    |-----------------|-------------|
    | 제1항 제1호 | 학교 예산안 및 결산 |
    | 제1항 제2호 | 학교 교육과정 운영 방법 |
    | 제1항 제4호 | 학교 급식 운영 방법 |
    | 제1항 제8호 | 학교 운동부 구성 및 운영 |

    학교 예산안은 학교운영위원회의 **필수 심의 사항**입니다.
  MD
  PROD_LESSON = "### 1. 학교 예산안은 학교운영위원회 심의가 필수입니다\n" \
                "초·중등교육법 제32조 제1항 제1호는 학교 예산안을 학교운영위원회의 심의 사항으로 명시하고 있습니다."

  # «제1항 제N호 … 핵심어» 를 뽑아 원문과 다른 번호에 붙은 핵심어를 돌려준다.
  def clause_mismatches(text)
    text.scan(/제1항\s*제(\d+)호[^\n]{0,20}?(학칙|예산안|교육과정|급식|운동부)/).filter_map do |no, word|
      "제#{no}호=#{word}" unless OFFICIAL[no.to_i] == word
    end
  end

  def seed_case(**attrs)
    AuditCase.create!({ title: SLUG, slug: SLUG, issue: "○○", category: "예산", detail: PROD_DETAIL, lesson: PROD_LESSON }.merge(attrs))
  end

  test "probe: 수리 전 운영 본문은 모순 4건을 잡는다 (검출기 음성 대조)" do
    assert_equal %w[제1호=예산안 제2호=교육과정 제4호=급식 제8호=운동부 제1호=예산안],
                 clause_mismatches(PROD_DETAIL + PROD_LESSON)
  end

  test "NORMAL: migration 후 detail 표·lesson 이 원문 호 번호와 일치한다" do
    ac = seed_case(legal_basis: "초·중등교육법 제32조 ①항 제2호(학교운영위원회 심의 사항 — 학교의 예산안과 결산)")
    capture_io { load MIGRATION }
    ac.reload
    assert_empty clause_mismatches(ac.detail)
    assert_empty clause_mismatches(ac.lesson)
    assert_includes ac.detail, "| 제1항 제2호 | 학교 예산안 및 결산 |"
    assert_includes ac.lesson, "제32조 제1항 제2호는 학교 예산안을"
    assert_match(/①항 제2호[^,]*예산안/, ac.legal_basis)
  end

  test "IDEMPOTENT: 두 번째 실행은 changes=0" do
    seed_case
    out1, = capture_io { load MIGRATION }
    out2, = capture_io { load MIGRATION }
    assert_match(/changes=2/, out1)
    assert_match(/changes=0/, out2)
  end

  test "DRY_RUN: 쓰지 않는다" do
    ac = seed_case
    ENV["DRY_RUN"] = "1"
    out, = capture_io { load MIGRATION }
    assert_match(/DRY_RUN changes=2/, out)
    assert_equal PROD_DETAIL, ac.reload.detail
  ensure
    ENV.delete("DRY_RUN")
  end

  test "EXCEPTION: 지문이 어긋나면 전체 롤백하고, 다른 사례는 건드리지 않는다" do
    ac = seed_case(lesson: "본문이 바뀌었다")
    other = AuditCase.create!(title: "o", slug: "other-case", issue: "○○", category: "예산", detail: PROD_DETAIL)
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_equal PROD_DETAIL, ac.reload.detail
    assert_equal PROD_DETAIL, other.reload.detail
  end

  test "SOURCE: seed 의 이 사례 블록도 원문 호 번호와 일치한다" do
    src = File.read(SEED)
    block = src[/find_or_create_by!\(slug: '#{SLUG}'\).*?\nend\n/m]
    assert block, "seed 블록을 찾지 못했다"
    assert_empty clause_mismatches(block)
    assert_match(/제32조 ①항 제2호[^,']*예산안/, block)
  end
end
