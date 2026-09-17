# frozen_string_literal: true

require "test_helper"

# 구기준 법령 수치 잔존 정정 회귀 (2026-09-17 전수감사 G-10·G-11·G-12·G-07, 15_STALE_VALUE_SWEEP).
# 원문: 지방계약법 시행규칙 제75조 · 같은 법 시행령 제25조·제30조·제42조·제50조 · 공무원 여비 규정 별표 2 · 공무원수당 등에 관한 규정 제18조.
class StaleLegalValuesTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260918110000_stale_legal_values.rb")
  STR = /"(?:[^"\\]|\\.)*"/
  EDITS = MIGRATION.read.scan(/^  \[ (\w+), (#{STR}), (#{STR}),\n    (#{STR}),\n    (#{STR}) \]/)
                   .map { |klass, *rest| [ klass.constantize, *rest.map { |s| JSON.parse(s) } ] }.freeze

  # 운영 덤프와 같은 모양: 텍스트 필드는 old 문자열을 이어 붙이고, jsonb 는 old 를 leaf 로 둔다(AuditCase.checkpoints 는 운영처럼 JSON 문자열).
  setup do
    EDITS.group_by { |klass, slug, _, _, _| [ klass, slug ] }.each do |(klass, slug), rows|
      attrs = { slug: slug }
      attrs[:name] = slug if klass.column_names.include?("name")
      attrs[:title] = slug if klass.column_names.include?("title")
      rows.group_by { |_, _, field, _, _| field }.each do |field, list|
        olds = list.map { |row| row[3] }
        attrs[field] =
          if klass.columns_hash[field].type != :jsonb then olds.join("\n\n")
          elsif klass == AuditCase then olds.to_json
          else olds.map { |old| { "text" => old, "note" => "유지" } }
          end
      end
      klass.new(attrs).save!(validate: false)
    end
  end

  def migrate = capture_io { load MIGRATION }.first

  test "NORMAL: 공사 지연배상금률 0.5/1,000 에 맞춰 사례 금액을 행 전체에서 다시 계산한다" do
    migrate
    ac = AuditCase.find_by!(slug: "penalty-reduction-unauthorized")
    row = [ ac.detail, ac.issue, ac.action_taken ].join("\n")
    assert_includes ac.detail, "0.5/1,000 (공사, 1일당"
    assert_includes ac.detail, "3년 누적 임의 감면액: 4,800만원"
    assert_equal 7, row.scan("2,800만원").size
    assert_not_includes row, "5,600만원"
    assert_not_includes row, "7,600만원"
    assert_not_includes row, "1/1,000 (공사"
  end

  test "EDGE: jsonb leaf 만 바꾸고 다른 값은 남기며, JSON 문자열로 저장된 checkpoints 도 고친다" do
    migrate
    stats = Topic.find_by!(slug: "travel-expense").quick_stats
    assert_equal [ "25,000원/일", "숙박비 (실비 상한)" ], stats.map { |h| h["text"] }
    assert_equal [ "유지" ], stats.map { |h| h["note"] }.uniq
    checkpoints = AuditCase.find_by!(slug: "single-quote-exceeds-limit").checkpoints
    assert_kind_of String, checkpoints
    assert_includes checkpoints, "2천만원 이하는 1인 견적 가능"
    assert_not_includes checkpoints, "5백만원"
  end

  test "LOWER_BOUND: 1인 견적 500만원·여비 일비 2만원·급식비 14만원·삭제 조문 인용이 남지 않는다" do
    migrate
    guide = Guide.find_by!(slug: "suui-contract-complete-3")
    assert_not_includes [ guide.sections, guide.rich_media ].to_json, "500만"
    assert_not_includes Guide.find_by!(slug: "travel-expense-complete-2").rich_media.to_json, "약 2만원/일"
    assert_not_includes Guide.find_by!(slug: "hr-welfare-complete-7").rich_media.to_json, "14만"
    topic = Topic.find_by!(slug: "lowest-bid-rate")
    body = [ topic.rule_content, topic.decree_content, topic.law_content, topic.faqs.to_json, topic.commentary ].join
    assert_not_includes body, "계약집행기준 제7조"
    assert_not_includes body, "2026.1.2"
    assert_includes topic.decree_content, "제42조의3"
  end

  test "UPPER_BOUND: 전 항목이 한 번씩 바뀌고 두 번째 실행은 아무것도 바꾸지 않는다" do
    assert_match(/changes=#{EDITS.size}\b/, migrate)
    assert_match(/changes=0\b/, migrate)
  end

  test "EXCEPTION: 지문이 안 맞으면 전체 롤백, DRY_RUN 은 쓰지 않는다" do
    ENV["DRY_RUN"] = "1"
    assert_match(/DRY_RUN changes=#{EDITS.size}\b/, migrate)
    ENV.delete("DRY_RUN")
    assert_includes AuditCase.find_by!(slug: "penalty-reduction-unauthorized").detail, "5,600만원"

    Topic.find_by!(slug: "travel-expense").update_columns(qa_content: "운영자가 고친 답변")
    assert_raises(RuntimeError) { migrate }
    assert_includes AuditCase.find_by!(slug: "penalty-reduction-unauthorized").detail, "5,600만원"
    assert_equal "운영자가 고친 답변", Topic.find_by!(slug: "travel-expense").qa_content
  ensure
    ENV.delete("DRY_RUN")
  end
end
