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
end
