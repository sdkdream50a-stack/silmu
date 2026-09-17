# frozen_string_literal: true

require "test_helper"

# 구기준 사실 정정 content migration 회귀 (2026-09-17 G-10·G-11·G-12).
# 운영 값으로 한 dry-run 은 21건 적용·재실행 0건이었다. 이 테스트는 같은 치환표로 레코드를 만들어
# 적용·멱등·부분 적용 금지(누락 시 전체 롤백)를 고정한다.
class ContentStaleFactsMigrationTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917121000_content_stale_facts_penalty_travel_quote.rb")

  def subs
    src = MIGRATION.read
    eval(src[/^subs = \[.*?^\]$/m].sub(/\Asubs = /, "")) # rubocop:disable Security/Eval
  end

  def seed_records!
    subs.group_by { |k, slug, _, _| [ k, slug ] }.each do |(klass, slug), rows|
      rec = klass.new(slug: slug)
      rec.title = slug if rec.respond_to?(:title=)
      rec.name = slug if rec.respond_to?(:name=)
      rows.each do |_, _, column, pairs|
        text = pairs.map(&:first).join("\n\n")
        json_col = klass.columns_hash[column.to_s].type.in?(%i[json jsonb])
        rec.public_send("#{column}=", json_col ? { "items" => [ text ] } : text)
      end
      rec.save!(validate: false)
    end
  end

  def all_text
    subs.map { |klass, slug, column, _| klass.find_by!(slug: slug).public_send(column).to_json }.join
  end

  test "NORMAL: every stale string is replaced and IDEMPOTENT on re-run" do
    seed_records!
    out1, = capture_io { load MIGRATION }
    out2, = capture_io { load MIGRATION }
    assert_match(/applied=21/, out1)
    assert_match(/applied=0/, out2)
    text = all_text
    subs.each { |*, pairs| pairs.each { |from, _| assert_not_includes text, from.to_json[1..-2] } }
    assert_includes text, "0.5/1,000"
    assert_includes text, "25,000원"
  end

  test "EXCEPTION: a missing stale string rolls back everything" do
    seed_records!
    Topic.find_by!(slug: "travel-expense").update_columns(summary: "이미 다른 문구")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes Topic.find_by!(slug: "penalty-reduction-procedure").commentary, "1/1000",
                    "앞선 레코드의 치환이 롤백되지 않았다"
  end
end
