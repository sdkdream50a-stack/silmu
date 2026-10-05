# frozen_string_literal: true

require "test_helper"

# F3/F4 (2026-10-05 AdSense readiness audit) — 가상(SIMULATED) 사례 노출 경로와 재구성 표기 모순.
#   F3  재구성 상세: «가상 시나리오» 꼬리 문구 → 사실대로 · `verified` 아이콘은 원문 근거(REAL) 사례에만
#   F4a 토픽 «관련 감사사례»에서 SIMULATED 제외
#   F4b /audit-cases 기본 목록에서 SIMULATED 제외, kind=scenario 필터를 고를 때만 표시
#   F4c noindex(SIMULATED) 상세·시나리오 목록에는 AdSense 로더·광고 단위 없음
# 각 판정은 양성대조(있어야 할 곳에는 여전히 있다)와 음성대조(없어야 할 곳에는 없다)를 함께 둔다.
class AuditCaseSimulatedExposureTest < ActionDispatch::IntegrationTest
  TAIL = "※ 본 사례는 경기도교육청 「2021 감사사례집」(p.76) 패턴을 기반으로 학습용으로 재구성한 **가상 시나리오**입니다. " \
         "특정 학교의 실제 사례가 아니며 학습·실무 적용을 위한 교육용 자료입니다."
  DOC = { "url" => "https://www.goe.go.kr/x.pdf", "publisher" => "경기도교육청 감사관실",
          "publication" => "감사사례집", "year" => 2021, "page" => 76 }.freeze

  setup do
    Rails.cache.clear
    @topic = Topic.create!(name: "F4 토픽", slug: "f4-host-topic", category: "contract", sector: :common,
                           keywords: "분할계약", summary: "분할계약 요약", published: true)
    base = { category: "수의계약", severity: "보통", issue: "분할 수의계약 지적.", legal_basis: "지방계약법 시행령 제30조",
             lesson: "분할 금지.", sector: :common, published: true, topic_slug: @topic.slug }
    @simulated = AuditCase.create!(base.merge(title: "F4 가상 사례", slug: "f4-sim-case",
                                              source_type: "SILMU_SIMULATED_CASE", detail: "본문\n\n#{TAIL}"))
    @reconstructed = AuditCase.create!(base.merge(title: "F4 재구성 사례", slug: "f4-recon-case", source: DOC,
                                                  source_type: "SILMU_RECONSTRUCTED_CASE", is_reconstructed: true,
                                                  verification_status: "RECONSTRUCTED", detail: "본문\n\n#{TAIL}"))
    @actual = AuditCase.create!(base.merge(title: "F4 실제 사례", slug: "f4-actual-case", source: DOC,
                                           source_url: DOC["url"], source_type: "ACTUAL_AUDIT",
                                           verification_status: "OFFICIAL_SOURCE_VERIFIED"))
  end

  def as_production
    original = Rails.env
    Rails.env = "production"
    yield
  ensure
    Rails.env = original.to_s
  end

  def badge_icon(body)
    # 검증 배지(aria-label="콘텐츠 검증 정보") 안의 아이콘 이름
    body[/aria-label="콘텐츠 검증 정보"[^>]*>\s*<span class="material-symbols-outlined[^"]*"[^>]*>([a-z_]+)</, 1]
  end

  # ── F3 ──────────────────────────────────────────────────────────
  test "F3: reconstructed page states the truthful basis and never says «가상 시나리오»" do
    get audit_case_url(@reconstructed.slug)
    assert_response :success
    refute_includes response.body, "가상 시나리오"
    assert_includes response.body, "(p.76) 지적 유형을 바탕으로 학습용으로 재구성한 사례입니다."
    assert_includes response.body, "경기도교육청 감사관실 「감사사례집」(2021) p.76 기반 재구성 · 기관·인물·금액 등 일부 각색"
  end

  test "F3 negative control: simulated page keeps the «가상 시나리오» wording" do
    get audit_case_url(@simulated.slug)
    assert_response :success
    assert_includes response.body, "가상 시나리오"
    refute_includes response.body, "기반 재구성 · 기관·인물·금액 등 일부 각색"
  end

  test "F3: verified icon only on REAL (document-backed) cases" do
    get audit_case_url(@actual.slug)
    assert_equal "verified", badge_icon(response.body), "POSITIVE CONTROL: 원문 근거 사례의 배지 아이콘이 verified 가 아니다"

    [ @reconstructed, @simulated ].each do |ac|
      get audit_case_url(ac.slug)
      icon = badge_icon(response.body)
      assert icon.present?, "#{ac.slug}: 배지를 찾지 못했다 — 판정이 공허하다"
      refute_equal "verified", icon, "#{ac.slug}: REAL 이 아닌 사례에 verified 아이콘"
    end
  end

  # ── F4a ─────────────────────────────────────────────────────────
  test "F4a: topic related audit cases exclude simulated, keep reconstructed and actual" do
    slugs = RelatedContentResolver.new(@topic).audit_cases.map(&:slug)
    assert_includes slugs, @reconstructed.slug
    assert_includes slugs, @actual.slug
    refute_includes slugs, @simulated.slug
  end

  test "F4a: fallback (no topic_slug) also excludes simulated" do
    [ @simulated, @reconstructed ].each { |ac| ac.update_columns(topic_slug: nil) }
    other = Topic.create!(name: "F4 다른 토픽", slug: "f4-other-topic", category: "contract", sector: :common,
                          keywords: "무관키워드", published: true)
    slugs = RelatedContentResolver.new(other).audit_cases.map(&:slug)
    assert_includes slugs, @reconstructed.slug, "POSITIVE CONTROL: category fallback 이 재구성 사례를 못 찾는다"
    refute_includes slugs, @simulated.slug
  end

  test "F4a: topic page does not render the simulated case card" do
    get topic_url(@topic.slug)
    assert_response :success
    assert_includes response.body, @reconstructed.title
    refute_includes response.body, @simulated.title
  end

  # ── F4b ─────────────────────────────────────────────────────────
  test "F4b: default /audit-cases listing excludes simulated" do
    get audit_cases_url
    assert_response :success
    assert_includes response.body, @reconstructed.title
    assert_includes response.body, @actual.title
    refute_includes response.body, @simulated.title
    assert_no_match(/<meta name="robots" content="[^"]*noindex/, response.body)
  end

  test "F4b: explicit scenario filter shows only simulated and is noindex" do
    get audit_cases_url(kind: "scenario")
    assert_response :success
    assert_includes response.body, @simulated.title
    refute_includes response.body, @reconstructed.title
    assert_match(/<meta name="robots" content="noindex, follow"/, response.body)
  end

  test "F4b: the scenario filter option is offered on the default listing" do
    get audit_cases_url
    assert_includes response.body, "kind=scenario"
  end

  # ── F4c ─────────────────────────────────────────────────────────
  test "F4c POSITIVE CONTROL: indexable audit case pages still render AdSense in production" do
    host! "silmu.kr"
    [ @reconstructed, @actual ].each do |ac|
      as_production { get "/audit-cases/#{ac.slug}" }
      assert_response :success
      assert_includes response.body, "adsbygoogle.js", "#{ac.slug}: 색인 사례에서 광고 로더가 사라졌다"
      assert_includes response.body, 'class="adsbygoogle"', "#{ac.slug}: 색인 사례에서 광고 단위가 사라졌다"
    end
    as_production { get "/audit-cases" }
    assert_includes response.body, "adsbygoogle.js", "기본 목록에서 광고 로더가 사라졌다"
  end

  test "F4c: simulated (noindex) audit case page renders no AdSense in production" do
    host! "silmu.kr"
    as_production { get "/audit-cases/#{@simulated.slug}" }
    assert_response :success
    assert_match(/<meta name="robots" content="noindex, follow"/, response.body)
    refute_includes response.body, "adsbygoogle"
    refute_includes response.body, "pagead2.googlesyndication.com"
  end

  test "F4c: scenario listing renders no AdSense in production" do
    host! "silmu.kr"
    as_production { get "/audit-cases?kind=scenario" }
    assert_response :success
    refute_includes response.body, "adsbygoogle"
  end
end
