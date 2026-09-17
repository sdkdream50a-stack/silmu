# frozen_string_literal: true

require "test_helper"

# 계약보증금·입찰보증금 면제 기준 정정 회귀 (2026-09-17 G-37). 원문: 지방계약법 시행령 제37조 제3항·제53조.
class GuaranteeExemptionThresholdsTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917230000_guarantee_exemption_thresholds.rb")

  def self.data = eval(MIGRATION.read.split("deep_sub = lambda")[0] + "\n[field_replacements, faqs_answers, subs]") # rubocop:disable Security/Eval

  setup do
    fields, answers, subs = self.class.data
    attrs = fields.to_h { |column, fingerprint, _| [ column, "#{fingerprint}\n종전 본문 3천만원 이하 면제" ] }
    attrs[:faqs] = answers.keys.map { |q| { "question" => q, "answer" => "소액 계약(예: 3천만원 이하)" } }
    attrs[:quick_stats] = [ { "label" => "면제 가능 대상", "value" => "국가·지자체·공공기관 / 소액 계약" } ]
    Topic.new({ slug: "contract-guarantee-exemption", name: "면제", category: "contract", sector: "common" }.merge(attrs)).save!(validate: false)
    subs.group_by(&:first).each do |slug, entries|
      cols = entries.group_by { |e| e[1] }.to_h do |column, es|
        froms = es.map { |e| e[2] }
        [ column, column == :faqs ? froms.map { |f| { "answer" => f } } : froms.join("\n") ]
      end
      Topic.new({ slug: slug, name: slug, category: "contract", sector: "common" }.merge(cols)).save!(validate: false)
    end
  end

  def blob(slug) = Topic.find_by!(slug: slug).attributes.slice("summary", "commentary", "decree_content", "practical_tips", "faqs", "quick_stats", "rule_content", "regulation_content", "qa_content").to_json

  test "NORMAL: 면제 금액 기준은 계약금액 5천만원 (시행령 제53조 제1항 제2호)" do
    capture_io { load MIGRATION }
    t = Topic.find_by!(slug: "contract-guarantee-exemption")
    assert_includes t.summary, "5천만원 이하"
    assert_includes t.decree_content, "계약금액이 5천만원 이하인 계약을 체결하는 경우"
    assert_equal "계약금액 5천만원 이하", t.quick_stats.find { |i| i["label"] == "금액 면제" }["value"]
    assert_not_includes t.faqs.to_json, "3천만원 이하)"
  end

  test "EDGE: 입찰보증금에는 금액 기준 면제가 없다 (시행령 제37조 제3항)" do
    capture_io { load MIGRATION }
    text = blob("bid-deposit")
    assert_not_includes text, "2천만원 이하: 면제"
    assert_not_includes text, "보통 5천만원 미만"
    assert_includes text, "금액 기준"
  end

  test "LOWER_BOUND: performance-guarantee 2천만원 면제 문구가 모두 5천만원으로" do
    capture_io { load MIGRATION }
    assert_no_match(/2천만\S* ?이하[^"]{0,10}면제/, blob("performance-guarantee"))
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: a field edited since the audit aborts the whole run" do
    Topic.find_by!(slug: "contract-guarantee-exemption").update_columns(commentary: "운영자가 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes Topic.find_by!(slug: "bid-deposit").practical_tips, "2천만원 이하: 면제 가능", "부분 적용 금지"
  end
end
