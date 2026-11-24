require "test_helper"

SETTLEMENT_APPROVAL_CORRECTION_LIBRARY_ONLY = true unless defined?(SETTLEMENT_APPROVAL_CORRECTION_LIBRARY_ONLY)
load Rails.root.join("db/content_migrations/20261125090000_settlement_approval_decree82.rb").to_s

class SettlementApprovalCorrectionTest < ActiveSupport::TestCase
  M = SettlementApprovalCorrection20261125

  test "가드 필드마다 데이터 파일이 있다" do
    M::TOPIC_GUARDS.each { |slug, g| g.each_key { |f| assert M.value(slug, f), "#{slug}.#{f}" } }
    M::AUDIT_GUARDS.each { |slug, g| g.each_key { |f| assert M.value("audit-#{slug}", f), "#{slug}.#{f}" } }
  end

  test "운영값이 가드와 다르면 아무것도 쓰지 않고 실패한다" do
    setup_records { |_field, _new| "다른 사람이 고친 값" }
    before = Topic.find_by!(slug: "budget-settlement").summary

    error = assert_raises(RuntimeError) { M.run!(dry_run: false) }
    assert_match "아무것도 쓰지 않음", error.message
    assert_equal before, Topic.find_by!(slug: "budget-settlement").summary
  end

  test "이미 새 값이면 변경 없이 통과한다(멱등)" do
    setup_records { |_field, new_value| new_value }
    plans = M.run!(dry_run: false)
    assert plans.all? { |p| p[:changes].empty? }
  end

  private

  def setup_records
    M::TOPIC_GUARDS.each do |slug, g|
      topic = Topic.find_or_initialize_by(slug: slug)
      topic.name ||= slug
      g.each_key { |f| topic[f] = yield(f, M.value(slug, f)) }
      topic.save!(validate: false)
    end
    M::AUDIT_GUARDS.each do |slug, g|
      audit = AuditCase.find_or_initialize_by(slug: slug)
      audit.title ||= slug
      g.each_key { |f| audit[f] = yield(f, M.value("audit-#{slug}", f)) }
      audit.save!(validate: false)
    end
  end
end
