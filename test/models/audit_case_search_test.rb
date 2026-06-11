# frozen_string_literal: true

require "test_helper"

class AuditCaseSearchTest < ActiveSupport::TestCase
  test "멀티워드 AND: 전 토큰 매칭 사례만 반환" do
    results = AuditCase.search_by_query("수의계약 분할")
    assert_includes results.map(&:slug), "test-split-contract"
  end

  test "단일 토큰 매칭" do
    results = AuditCase.search_by_query("수도광열비")
    assert_includes results.map(&:slug), "test-budget-misuse"
  end

  test "랭킹: title 매칭이 issue 매칭보다 상위 (view_count 무관)" do
    results = AuditCase.search_by_query("수의계약", limit: 5).to_a
    title_idx = results.index { |c| c.slug == "test-split-contract" }
    issue_idx = results.index { |c| c.slug == "test-contract-issue-only" }
    assert title_idx, "title 매칭 사례가 결과에 있어야 함"
    assert issue_idx, "issue 매칭 사례가 결과에 있어야 함"
    assert title_idx < issue_idx, "title 매칭(#{title_idx})이 issue 매칭(#{issue_idx})보다 앞서야 함"
  end

  test "빈 쿼리는 빈 결과" do
    assert_empty AuditCase.search_by_query("")
  end
end
