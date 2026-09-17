# frozen_string_literal: true

require "test_helper"

# 여비 구기준 jsonb 잔존·오인용 조문 정정 회귀 (2026-09-17 G-37). 근거: 공무원 여비 규정 별표 2(2026.6.30. 개정).
class TravelValuesCitationFixesTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917180000_travel_values_and_citation_fixes.rb")

  setup do
    @settle = topic("travel-expense-settlement",
      faqs: [ { "question" => "q", "answer" => "일비는 직급 공통 1일 20,000원, 식비는 4급 이상 1일 25,000원·5급 이하 20,000원으로 정산합니다." },
              { "question" => "q", "answer" => "국가공무원법 제48조(여비)의 위임에 따른 규정" } ],
      quick_stats: [ { "label" => "일비", "note" => "직급 공통", "value" => "2만원/일" }, { "label" => "식비", "note" => "5급 이하 2만원", "value" => "2.5만원/일" } ])
    @domestic = topic("domestic-travel-allowance",
      faqs: [ { "answer" => "직급에 관계없이 1일 20,000원입니다." },
              { "answer" => "식비는 4급 이상 1일 25,000원, 5급 이하 20,000원입니다. 숙박비 상한은 4급 이상 70,000원, 5급 이하 60,000원이며 실비로 지급됩니다." },
              { "answer" => "공무원여비규정 제16조(국내 여비의 지급 기준) 및 동 규정 별표(직급별 여비 기준)에 따릅니다." } ],
      quick_stats: [ { "label" => "일비", "note" => "직급 공통", "value" => "2만원/일" }, { "label" => "식비", "note" => "5급 이하 2만원", "value" => "2.5만원/일" },
                     { "label" => "숙박비 상한", "note" => "5급 이하 6만원", "value" => "7만원/일" } ])
    @guide = guide("travel-expense-complete-2", {
      "hook" => "출장 다녀온 선배가 식비 2만5천 원을 받았는데, 저는 2만 원밖에 안 나왔습니다. 같은 식당을 갔는데 왜 다를까요? 직급이 달랐기 때문입니다. 여비는 직급에 따라 다릅니다. 오늘 이 기준을 완벽히 정리합니다.",
      "laws" => [ { "name" => "공무원여비규정 별표 2", "text" => "국내 여비 지급 기준표 — 직급별 일비·식비·숙박비 금액 규정" } ],
      "real_case" => "【실제 감사 지적 사례】 B 교육청 담당자가 6급임에도 불구하고 시스템 설정 오류로 5급 기준 식비를 2년간 지급받았습니다. 감사에서 초과 지급분 전액(약 18만 원) 반납 처분을 받았습니다. 시스템 오류라도 본인이 확인했어야 했다는 판단이었습니다."
    })
    @contract_guide = guide("suui-contract-complete-5", { "laws" => [ { "name" => "지방계약법 시행령 제92조", "text" => "대금 지급 기한 및 절차" } ] })
  end

  def topic(slug, **attrs) = Topic.new({ slug: slug, name: slug, category: "travel", sector: "common" }.merge(attrs)).tap { |t| t.save!(validate: false) }
  def guide(slug, sections) = Guide.new(slug: slug, title: slug, sections: sections).tap { |g| g.save!(validate: false) }

  test "NORMAL: jsonb FAQ values follow 별표 2 (25,000원, no grade difference)" do
    capture_io { load MIGRATION }
    faqs = @domestic.reload.faqs.to_json
    assert_not_includes faqs, "20,000"
    assert_not_includes faqs, "5급 이하"
    assert_includes faqs, "서울 100,000원"
    assert_includes @settle.reload.faqs.to_json, "1일 각 25,000원"
  end

  test "EDGE: quick_stats hashes are corrected in place" do
    capture_io { load MIGRATION }
    stats = @domestic.reload.quick_stats
    assert_equal "2.5만원/일", stats[0]["value"]
    assert_equal "직급 공통", stats[1]["note"]
    assert_equal "서울 10만·광역시 8만·그 밖 7만원", stats[2]["value"]
  end

  test "LOWER_BOUND: guide no longer claims grade-based meal allowance or a fabricated audit case" do
    capture_io { load MIGRATION }
    sections = @guide.reload.sections.to_json
    assert_not_includes sections, "직급이 달랐기 때문입니다"
    assert_not_includes sections, "실제 감사 지적 사례"
    assert_includes @contract_guide.reload.sections.to_json, "지방계약법 시행령 제67조"
  end

  test "UPPER_BOUND: second run changes nothing" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/substitutions=0/, out)
  end

  test "EXCEPTION: missing stale text aborts the whole run" do
    @settle.update_columns(faqs: [ { "answer" => "운영자가 고친 본문" } ])
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes @domestic.reload.faqs.to_json, "20,000", "부분 적용 금지"
  end
end
