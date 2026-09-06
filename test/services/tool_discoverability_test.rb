# frozen_string_literal: true

require "test_helper"

# P2 R1 — 기존 도구 발견성.
#
# P2 감사 실측: 상위 기회 질의 여러 건이 "답을 계산하는 도구가 이미 있는데 검색에 안 잡힌다" 였다.
# 예) "수의계약 한도" — `계약방식 결정 도우미` 가 물품·용역 2천만/5천만, 공사 종합 4억 분기를
#     실제로 판정하는데, title/desc/keywords 어디에도 "한도" 라는 낱말이 없어 매칭 0건이었다.
#
# 그래서 이 테스트는 **양성만 보지 않는다.** keyword 를 넣으면 양성은 언제든 늘릴 수 있고,
# 그 대가로 무관한 질의에 도구가 딸려 나오면 그건 개선이 아니라 stuffing 이다.
# precision(음성대조)과 recall(양성)을 같은 스위트에서 함께 고정한다.
#
# 매칭 규칙은 ChatbotController#search_tools 와 같다 — 토큰 AND, haystack substring.
# 컨트롤러(P1.6 인접 파일)를 수정하지 않기 위해 같은 식을 여기서 재현한다.
class ToolDiscoverabilityTest < ActiveSupport::TestCase
  def registry
    @registry ||= Class.new do
      include ToolsHelper
      include Rails.application.routes.url_helpers
    end.new.tools_registry
  end

  def tool_titles_for(query)
    variants = SearchQueryParser.tokens(query)
    return [] if variants.empty?

    registry.select { |tool|
      haystack = [ tool[:title], tool[:desc], tool[:category], tool[:domain], tool[:keywords] ]
                   .compact.join(" ").downcase
      variants.all? { |vs| vs.any? { |v| haystack.include?(v.downcase) } }
    }.first(4).map { |t| t[:title] }
  end

  # ── 양성: 도구가 실제로 그 질문을 푸는 것만 넣었다 ──
  # (각 항목의 intent 근거는 docs/silmu-p2/12_R1_TOOL_DISCOVERABILITY.md)
  POSITIVE = {
    "수의계약 한도"  => "계약방식 결정 도우미",
    "수의계약한도"   => "계약방식 결정 도우미",
    "소액수의"      => "계약방식 결정 도우미",
    "분할발주"      => "분할계약 판단 체크리스트",
    "분리 발주"     => "분할계약 판단 체크리스트",
    "수입인지"      => "계약보증금 계산기",
    "보조금정산"    => "보조금 정산 체크리스트",
    "국외출장"      => "여비계산기",
    "국외"         => "여비계산기"
  }.freeze

  POSITIVE.each do |query, expected|
    test "발견성 — '#{query}' 는 #{expected} 를 찾아낸다" do
      assert_includes tool_titles_for(query), expected,
                      "답을 가진 도구가 이미 있는데 검색에서 못 찾으면 사용자에겐 없는 것과 같다"
    end
  end

  # ── 음성: 도구가 못 푸는 질의에 도구가 뜨면 안 된다 ──
  # 여기에 있는 질의는 P2 감사에서 TOOL_MISSING 으로 판정된 것들이다.
  # (검수·업무추진비·일상경비·겸직·선금 — 해당 판정을 하는 도구가 실제로 없다)
  NEGATIVE = %w[
    병가 특별휴가 육아휴직 겸직 검수 선금 업무추진비 일상경비
  ].freeze

  NEGATIVE.each do |query|
    test "오매칭 금지 — '#{query}' 에는 도구가 붙지 않는다" do
      assert_empty tool_titles_for(query),
                   "도구가 실제로 해결하지 못하는 질의에 keyword 를 붙이면 그건 SEO stuffing 이다"
    end
  end

  test "오매칭 금지 — 다중어 질의에도 무관한 도구가 붙지 않는다" do
    [ "병가 진단서", "지급 기준", "정보공개 처리기한", "민원 처리기한", "기록물 이관" ].each do |query|
      assert_empty tool_titles_for(query), "'#{query}' 에 도구가 붙었다"
    end
  end

  # ── 과승격 금지: 넓은 질의의 결과가 이번 변경으로 늘어나면 안 된다 ──
  # 변경 전 실측(2026-09-06): "계약" 4건 · "출장비" 1건 · "이월" 1건 · "전용" 1건.
  BASELINE = {
    "계약"   => 4,
    "출장비" => 1,
    "이월"   => 1,
    "전용"   => 1,
    "인지세" => 1,
    "연말정산" => 1,
    "설계변경" => 1,
    "초과근무" => 1,
    "수도광열비" => 1,
    "집행률" => 1,
    # 독립검증 MEDIUM — `분할발주`·`분리발주` 를 넣으면 substring 매칭 특성상
    # **`발주` 단독 질의도 이 도구에 걸린다**(변경 전 0 → 후 1). 매칭 규칙이 토큰 AND +
    # substring 인 한 "발주" 를 포함한 키워드로는 이 파급을 피할 수 없다.
    # 관측상 `분할발주`(5)·`분리 발주`(3) 는 실질의이고 `발주` 단독은 후보에 오르지 못한 저빈도라
    # 이 파급을 **받아들이되 테스트로 고정**한다 — 모르고 생긴 것과 알고 남긴 것은 다르다.
    "발주" => 1
  }.freeze

  BASELINE.each do |query, count|
    test "과승격 금지 — '#{query}' 결과 수는 변경 전과 같은 #{count}건이다" do
      assert_equal count, tool_titles_for(query).size,
                   "keyword 보강이 넓은 질의의 결과를 부풀리면 정밀도가 떨어진다"
    end
  end

  test "'발주' 단독은 분할계약 체크리스트에만 붙는다 — 알고 남긴 파급" do
    assert_equal [ "분할계약 판단 체크리스트" ], tool_titles_for("발주")
  end

  test "'한도' 단독은 한도를 실제로 다루는 도구에만 붙는다" do
    titles = tool_titles_for("한도")

    assert_includes titles, "계약방식 결정 도우미"
    titles.each do |title|
      assert_match(/계약방식 결정 도우미|예비비 한도 계산기/, title,
                   "'한도' 가 무관한 도구까지 끌어오면 안 된다 — 실제로 한도를 산출하는 도구만")
    end
  end

  test "도구 개수는 변하지 않는다 — R1 은 keywords 만 만진다" do
    assert_equal ApplicationHelper::ACTIVE_TOOL_COUNT, registry.size
  end
end
