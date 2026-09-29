# frozen_string_literal: true

require "test_helper"

# 감사사례 P2/P3 잔여 정정(같은 판정 오류가 다른 필드에 남은 11문장) 회귀 — 2026-09-29.
# 운영 모양 = 시드(정정 후)에서 edits 를 되돌린 상태. 마이그레이션 결과가 시드와 같아야 한다.
class AuditTruthP2p3ResidualTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260929122000_audit_truth_p2p3_residual.rb")
  EDITS = eval(MIGRATION.read.split("\ncount_in = lambda").first + "\nedits") # rubocop:disable Security/Eval
  SLUGS = EDITS.map(&:first).uniq.freeze
  FIELDS = %w[issue detail lesson legal_basis].freeze
  SEEDS = %w[goe_2021_budget_execution_audit_cases goe_2021_school_contracts_pre_audit_cases goe_2021_school_funds_audit_cases
             goe_2021_supplies_audit_cases content_enrichment_phase2_edu_accounting_5_2026_05_18
             content_enrichment_phase2_edu_private_contract_7_2026_05_18
             sen_2025_school_accounting_audit_cases sen_2025_contracts_audit_cases].freeze
  STALE = [ "사업 종료 10일 이내 정산·공개 절차가 누락", "입찰 공고 1주일 +", "1주일 이상 게시했는가",
            "변상 책임 + 징계 동시", "변상 책임 + 견책 이상", "모든 안건 적법성 다툼", "입찰 공정성 훼손 (기초금액",
            "정확한 분기점 분할 | 의도성 명백", "의도성 입증이 가장 명확한 증거" ].freeze

  setup do
    capture_io { SEEDS.each { |f| load Rails.root.join("db/seeds/audit_cases/#{f}.rb") } }
    AuditCase.where(slug: SLUGS).update_all(view_count: 170)
    @expected = SLUGS.to_h { |s| [ s, snap(s) ] }
    @others = AuditCase.where.not(slug: SLUGS).order(:slug).map { |a| a.attributes.except("updated_at") }
    SLUGS.each do |slug|
      a = AuditCase.find_by!(slug: slug)
      a.update_columns(FIELDS.to_h { |f| [ f, revert(a.read_attribute(f), slug, f) ] })
    end
  end

  def snap(slug)
    a = AuditCase.find_by!(slug: slug)
    FIELDS.to_h { |f| [ f, a.read_attribute(f) ] }.merge("title" => a.title, "view_count" => a.view_count,
                                                          "target_agency" => a.target_agency)
  end

  def revert(value, slug, field)
    EDITS.select { |s, f, _, _| s == slug && f == field }.each { |_, _, old, new| value = value.to_s.sub(new) { old } }
    value
  end

  def body(slug) = FIELDS.map { |f| AuditCase.find_by!(slug: slug).read_attribute(f).to_s }.join("\n")

  def migrate(env = {})
    env.each { |k, v| ENV[k] = v }
    capture_io { load MIGRATION }.first
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  test "되돌린 상태에 옛 문구가 있다(구 상태 재현)" do
    all = SLUGS.map { |s| body(s) }.join("\n")
    STALE.each { |s| assert_includes all, s }
  end

  test "NORMAL: 결과가 정정된 시드와 같고 옛 문구는 사라진다" do
    assert_includes migrate, "changes=11"
    SLUGS.each { |s| assert_equal @expected[s], snap(s), s }
    all = SLUGS.map { |s| body(s) }.join("\n")
    STALE.each { |s| refute_includes all, s }
  end

  test "목록 밖 사례는 모든 속성이 그대로다(negative control)" do
    migrate
    assert_equal @others, AuditCase.where.not(slug: SLUGS).order(:slug).map { |a| a.attributes.except("updated_at") }
  end

  test "재실행 changes=0 · DRY_RUN 은 쓰지 않는다" do
    assert_includes migrate("DRY_RUN" => "1"), "DRY_RUN changes=11"
    assert_includes body("goe-2021-failed-bid-private-contract"), "변상 책임 + 징계 동시"
    migrate
    assert_includes migrate, "changes=0"
  end

  test "옛 문구가 없으면 전체 롤백" do
    AuditCase.find_by!(slug: "sen-2025-school-c-long-term-contract-violation").update_columns(lesson: "다른 본문")
    assert_raises(RuntimeError) { migrate }
    assert_includes body("goe-2021-failed-bid-private-contract"), "변상 책임 + 징계 동시"
  end
end
