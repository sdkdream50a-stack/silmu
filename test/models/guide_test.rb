require "test_helper"

class GuideTest < ActiveSupport::TestCase
  # ── series_episode_title ──────────────────────────────────────────────────

  test "series_episode_title: 시리즈 없는 가이드는 title 그대로 반환" do
    g = Guide.new(title: "수의계약 개요", slug: "test-no-series")
    assert_equal "수의계약 개요", g.series_episode_title
  end

  test "series_episode_title: Format A — '주제 — 완전정복 N편' 에서 주제만 추출" do
    g = Guide.new(title: "수의계약이란 무엇인가 — 왕초보 완전정복 1편",
                  slug: "test-format-a", series: "수의계약_완전정복", series_order: 1)
    assert_equal "수의계약이란 무엇인가", g.series_episode_title
  end

  test "series_episode_title: Format B — '완전정복 N편 — 주제' 에서 주제만 추출" do
    g = Guide.new(title: "지방보조금 완전정복 1편 — 지방보조금이란 무엇인가",
                  slug: "test-format-b", series: "지방보조금_완전정복", series_order: 1)
    assert_equal "지방보조금이란 무엇인가", g.series_episode_title
  end

  test "series_episode_title: 10편 이상 (두 자리 숫자) 도 올바르게 처리" do
    g = Guide.new(title: "Q&A 20문항 총정리 — 완전정복 10편",
                  slug: "test-ep10", series: "수의계약_완전정복", series_order: 10)
    assert_equal "Q&A 20문항 총정리", g.series_episode_title
  end

  # ── scopes ────────────────────────────────────────────────────────────────

  test "series_guides scope: series 있는 가이드만 반환" do
    skip "시드 데이터 없는 환경에서는 건너뜀" if Guide.count.zero?
    all_series = Guide.series_guides
    assert all_series.all? { |g| g.series.present? },
           "series_guides에 series가 nil인 레코드가 포함됨"
  end

  test "for_series scope: 특정 시리즈만 series_order 순으로 반환" do
    skip "시드 데이터 없는 환경에서는 건너뜀" if Guide.count.zero?
    series_name = Guide.series_guides.pick(:series)
    skip "완전정복 시리즈 데이터 없음" if series_name.nil?

    guides = Guide.for_series(series_name)
    assert guides.all? { |g| g.series == series_name },
           "for_series에 다른 시리즈 레코드가 포함됨"
    orders = guides.map(&:series_order)
    assert_equal orders.sort, orders, "for_series 결과가 series_order 오름차순이 아님"
  end

  # ── validation ────────────────────────────────────────────────────────────

  test "series_order uniqueness: 같은 시리즈 내 중복 series_order 거부" do
    existing = Guide.series_guides.where.not(series_order: nil).first
    skip "검증할 시리즈 가이드 없음" if existing.nil?

    dup = Guide.new(
      title: "중복 테스트",
      slug:  "dup-series-order-test-#{SecureRandom.hex(4)}",
      series: existing.series,
      series_order: existing.series_order
    )
    assert_not dup.valid?, "중복 series_order가 유효성 검사를 통과하면 안 됨"
    assert_includes dup.errors[:series_order], "has already been taken"
  end

  test "series_order uniqueness: 다른 시리즈의 같은 series_order는 허용" do
    existing = Guide.series_guides.where.not(series_order: nil).first
    skip "검증할 시리즈 가이드 없음" if existing.nil?

    g = Guide.new(
      title:        "다른 시리즈 테스트",
      slug:         "other-series-order-#{SecureRandom.hex(4)}",
      series:       "다른시리즈_테스트",
      series_order: existing.series_order
    )
    assert g.valid?, "다른 시리즈의 같은 series_order는 허용되어야 함"
  end
end
