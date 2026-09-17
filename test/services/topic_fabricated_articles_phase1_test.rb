# frozen_string_literal: true

require "test_helper"

# 토픽 가공·오번호 조문 정정 1차 회귀 (2026-09-17 G-36). 원문: law.go.kr.
class TopicFabricatedArticlesPhase1Test < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20260917150000_topic_fabricated_articles_phase1.rb")

  FAKES = {
    "inspection" => [ :decree_content, "### 제65조 (검사의 구분)\n③ 추정가격 5천만원 이하인 계약은 검사조서 작성을 생략할 수 있다." ],
    "payment" => [ :decree_content, "### 제55조 (준공대가의 지급)" ],
    "travel-expense" => [ :rule_content, "### 공무원 여비규정 제18조 (자가용 승용차 이용 시 운임)" ],
    "budget-carryover" => [ :rule_content, "### 제10조(명시이월비의 이월 절차)" ],
    "performance-bonus" => [ :law_content, "## 공무원보수법 제47조 (수당)" ],
    "annual-leave" => [ :law_content, "## 국가공무원법 제41조 (휴가)" ],
    "official-leave" => [ :law_content, "## 국가공무원법 제52조 (근무시간 등)" ],
    "vehicle-travel-allowance" => [ :law_content, "## 국가공무원법 제46조 (실비 변상)" ],
    "accommodation-allowance" => [ :law_content, "## 국가공무원법 제26조의5 (여비)" ],
    "year-end-settlement" => [ :rule_content, "### 소득세법 시행규칙 제107조 (교육비 세액공제 증명)" ],
    "spec-price-split-bid" => [ :decree_content, "**지방계약법 시행령 제18조 제3항**\n① 추정가격 **1억원 이상**" ]
  }.freeze

  setup do
    FAKES.each do |slug, (column, text)|
      Topic.new(slug: slug, name: slug, category: "contract", sector: "common", column => text).save!(validate: false)
    end
  end

  def field(slug) = Topic.find_by!(slug: slug).public_send(FAKES[slug][0])

  test "NORMAL: 검사조서 생략 기준은 원문대로 계약금액 3천만원" do
    capture_io { load MIGRATION }
    assert_includes field("inspection"), "계약금액 3천만원을 말한다"
    assert_not_includes field("inspection"), "5천만원 이하"
    assert_includes field("payment"), "제67조(대가의 지급)"
  end

  test "EDGE: 존재하지 않는 법령명·조문이 사라지고 실제 근거 조문이 들어간다" do
    capture_io { load MIGRATION }
    assert_includes field("performance-bonus"), "국가공무원법 제47조"
    assert_includes field("budget-carryover"), "제50조(세출예산의 이월)"
    assert_includes field("annual-leave"), "제67조(위임 규정)"
    %w[vehicle-travel-allowance accommodation-allowance].each { |s| assert_includes field(s), "제48조(실비 변상 등)" }
    assert_includes field("spec-price-split-bid"), "규격ㆍ기술평가위원회를 둔다"
    assert_not_includes field("spec-price-split-bid"), "① 추정가격"
  end

  test "LOWER_BOUND: 교체 필드는 모두 원문 출처 줄을 가진다" do
    capture_io { load MIGRATION }
    FAKES.each_key { |slug| assert_includes field(slug), "국가법령정보센터(law.go.kr)", slug }
  end

  test "UPPER_BOUND: 두 번째 실행은 아무것도 바꾸지 않는다" do
    capture_io { load MIGRATION }
    out, = capture_io { load MIGRATION }
    assert_match(/changes=0/, out)
  end

  test "EXCEPTION: 가공 문구가 없는 필드를 만나면 전체 롤백" do
    Topic.find_by!(slug: "payment").update_columns(decree_content: "운영자가 이미 손으로 고친 본문")
    assert_raises(RuntimeError) { capture_io { load MIGRATION } }
    assert_includes field("inspection"), "제65조 (검사의 구분)", "부분 적용 금지"
  end
end
