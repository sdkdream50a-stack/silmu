# frozen_string_literal: true

require "test_helper"

class TopicSearchTest < ActiveSupport::TestCase
  test "멀티워드 AND: 전 토큰이 매칭되는 토픽만 반환" do
    results = Topic.search_multiple("지방계약법 수의계약")
    slugs = results.map(&:slug)
    assert_includes slugs, "test-local-private-contract"
  end

  test "멀티워드 AND: 일부 토큰만 가진 토픽은 제외" do
    # "수의계약 절차": local_private_contract 는 두 토큰 모두 보유(매칭),
    # agency_takeover 는 "절차"만 보유 → AND 미충족으로 제외되어야 함.
    # (매칭 결과가 비지 않으므로 pg_search 폴백은 발동하지 않음)
    results = Topic.search_multiple("수의계약 절차")
    slugs = results.map(&:slug)
    assert_includes slugs, "test-local-private-contract"
    assert_not_includes slugs, "test-agency-takeover"
  end

  test "단일 토큰 쿼리는 기존과 동등하게 매칭" do
    results = Topic.search_multiple("수의계약")
    assert_includes results.map(&:slug), "test-local-private-contract"
  end

  test "동의어 확장: '성과급' 으로 성과상여금 토픽 매칭" do
    results = Topic.search_multiple("성과급")
    assert_includes results.map(&:slug), "test-performance-bonus"
  end

  test "랭킹: name 매칭이 keywords 매칭보다 상위" do
    results = Topic.search_multiple("검수").to_a
    name_idx = results.index { |t| t.slug == "test-inspection-name" }
    kw_idx   = results.index { |t| t.slug == "test-inspection-keyword" }
    assert name_idx, "name 매칭 토픽이 결과에 있어야 함"
    assert kw_idx, "keywords 매칭 토픽이 결과에 있어야 함"
    assert name_idx < kw_idx, "name 매칭(#{name_idx})이 keywords 매칭(#{kw_idx})보다 앞서야 함"
  end

  test "동의어 랭킹: '성과급' 검색 시 name 에 동의어(성과상여금)가 있는 토픽이 summary 매칭보다 상위" do
    results = Topic.search_multiple("성과급").to_a
    name_idx    = results.index { |t| t.slug == "test-performance-bonus" }
    summary_idx = results.index { |t| t.slug == "test-performance-summary-only" }
    assert name_idx, "name 동의어 매칭 토픽이 결과에 있어야 함"
    assert summary_idx, "summary 매칭 토픽이 결과에 있어야 함"
    assert name_idx < summary_idx, "name 동의어 매칭(#{name_idx})이 summary 매칭(#{summary_idx})보다 앞서야 함"
  end

  test "2자 쿼리 공백제거 오탐 없음: '관인' 이 '기관 인수' 에 매칭되지 않음" do
    results = Topic.search_multiple("관인")
    assert_not_includes results.map(&:slug), "test-agency-takeover"
  end

  test "빈 쿼리는 빈 결과" do
    assert_empty Topic.search_multiple("")
  end

  # ---- P1.6 점진적 완화 (전 토큰 AND 가 0건일 때만 발동) ----
  # NOTE: 토픽 픽스처를 추가하지 말 것. test/fixtures/topics.yml 상단 경고 참조.

  test "완화: 전 토큰 AND 가 0건이면 과반 매칭으로 구제한다" do
    # "없는토큰zzz" 때문에 AND 는 0건. 과반(3중 2)인 지방계약법+수의계약 은 살아야 한다.
    results = Topic.search_multiple("지방계약법 수의계약 없는토큰zzz")
    assert_includes results.map(&:slug), "test-local-private-contract"
  end

  test "완화: 자연어 질문이 0건이 되지 않는다" do
    # "수의계약 절차는 며칠 걸리나요" — 며칠은 stopword, 절차는→절차, 걸리나요는 어디에도 없음.
    # 종전에는 AND 가 깨져 0건이었다.
    results = Topic.search_multiple("수의계약 절차는 며칠 걸리나요")
    assert_includes results.map(&:slug), "test-local-private-contract"
  end

  # 순위 중립 표현식. Postgres 는 ORDER BY 의 벌거벗은 정수를 "select list 위치"로 해석하므로
  # 상수 0 을 그대로 넘기면 안 된다(컬럼 참조식이어야 표현식으로 읽힌다).
  NEUTRAL_RANK = "(view_count * 0)"

  # relaxed_match 를 직접 호출해 완화 규칙 자체를 고정한다.
  # 통합 경로(search_multiple)만으로는 pg_search 폴백이 같은 답을 내주는 구간이 있어
  # "완화가 실제로 돌았는가"를 구분하지 못한다 — 그래서 프리미티브를 직접 못 박는다.
  test "relaxed_match: 과반 이상 매칭된 토픽만 반환한다" do
    clauses = [
      Topic.sanitize_sql_array([ "name ILIKE ?", "%지방계약법%" ]),
      Topic.sanitize_sql_array([ "name ILIKE ?", "%수의계약%" ]),
      Topic.sanitize_sql_array([ "name ILIKE ?", "%없는토큰zzz%" ])
    ]
    slugs = Topic.relaxed_match(clauses, NEUTRAL_RANK, 10).map(&:slug)
    assert_includes slugs, "test-local-private-contract", "3중 2 매칭은 채택돼야 함"
    assert_not_includes slugs, "test-agency-takeover", "0 매칭은 기각돼야 함"
  end

  test "relaxed_match: 과반 미달은 기각한다" do
    clauses = [
      Topic.sanitize_sql_array([ "name ILIKE ?", "%인수%" ]),
      Topic.sanitize_sql_array([ "name ILIKE ?", "%없는토큰zzz%" ]),
      Topic.sanitize_sql_array([ "name ILIKE ?", "%또없는토큰yyy%" ])
    ]
    # agency_takeover 는 3중 1 만 매칭 → 과반(2) 미달로 기각.
    assert_not_includes Topic.relaxed_match(clauses, NEUTRAL_RANK, 10).map(&:slug), "test-agency-takeover"
  end

  test "relaxed_match: 매칭 토큰이 많은 토픽이 앞선다 (view_count 가 반대로 걸려 있어도)" do
    # 이 단언이 hit_count 정렬에만 의존하도록 view_count 를 일부러 역방향으로 고른다.
    #   inspection_name_match     : 2 매칭 · view_count 5
    #   inspection_keyword_match  : 1 매칭 · view_count 999
    # hit_count DESC 가 없으면 view_count DESC 가 이겨서 순서가 뒤집힌다.
    clauses = [
      Topic.sanitize_sql_array([ "name ILIKE ? OR keywords ILIKE ?", "%검수%", "%검수%" ]),
      Topic.sanitize_sql_array([ "keywords ILIKE ?", "%검사%" ])
    ]
    slugs = Topic.relaxed_match(clauses, NEUTRAL_RANK, 10).map(&:slug)
    two_idx = slugs.index("test-inspection-name")     # 검수(name) + 검사(keywords) = 2
    one_idx = slugs.index("test-inspection-keyword")  # 검수(keywords) = 1
    assert two_idx, "2토큰 매칭이 결과에 있어야 함"
    assert one_idx, "1토큰 매칭이 결과에 있어야 함"
    assert two_idx < one_idx, "매칭 수가 많은 쪽(#{two_idx})이 적은 쪽(#{one_idx})보다 앞서야 함"
  end

  test "relaxed_match: 토큰이 1개면 발동하지 않는다" do
    clauses = [ Topic.sanitize_sql_array([ "name ILIKE ?", "%수의계약%" ]) ]
    assert_nil Topic.relaxed_match(clauses, NEUTRAL_RANK, 10)
  end

  test "완화: 과반 미달 토픽은 제외한다 (pg_search 폴백과 구별되는 지점)" do
    # 4토큰 → 과반 2. local_private_contract 는 지방계약법+수의계약 = 2 (채택),
    # agency_takeover 는 인수 = 1 (기각). pg_search 폴백은 이 구분을 하지 못하므로
    # 이 단언이 곧 "완화 경로가 실제로 돌았다"는 증거다.
    results = Topic.search_multiple("지방계약법 수의계약 인수 없는토큰zzz").to_a
    slugs = results.map(&:slug)
    assert_includes slugs, "test-local-private-contract"
    assert_not_includes slugs, "test-agency-takeover"
  end

  test "완화: 정확 매칭이 있으면 발동하지 않는다" do
    # AND 가 성립하므로 절반만 가진 토픽(test-agency-takeover)은 끼어들면 안 된다.
    results = Topic.search_multiple("지방계약법 수의계약")
    slugs = results.map(&:slug)
    assert_includes slugs, "test-local-private-contract"
    assert_not_includes slugs, "test-agency-takeover"
  end

  test "완화: 단일 토큰 쿼리에는 적용하지 않는다" do
    # 토큰이 1개면 완화는 AND 와 같아져 의미가 없다 → 기존 pg_search 폴백 경로를 유지한다.
    results = Topic.search_multiple("관인")
    assert_not_includes results.map(&:slug), "test-agency-takeover"
  end
end
