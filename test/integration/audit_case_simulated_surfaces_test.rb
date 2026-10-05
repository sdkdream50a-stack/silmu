# frozen_string_literal: true

require "test_helper"

# F4 후속 (2026-10-05 리뷰 A-M2) — PR #170 이 토픽·기본 목록·광고에서 뺀 가상(SIMULATED·noindex) 사례가
#   남아 있던 공개·크롤 가능 표면: 홈 감사사례 카드 · RSS · llms-full.txt · IndexNow 제출 · 상세의 «유사 감사사례» ·
#   Topic#related_audit_cases. 판정 기준은 #170 과 같은 `search_indexable` 스코프(새 분류 없음).
# 각 표면은 양성대조(비가상 사례는 그대로 나온다)와 음성대조(가상 사례는 없다)를 함께 둔다.
class AuditCaseSimulatedSurfacesTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  CATEGORY = "F4후속전용분류"

  setup do
    Rails.cache.clear
    @topic = Topic.create!(name: "F4 후속 토픽", slug: "f4b-host-topic", category: "contract", sector: :common,
                           keywords: "분할계약", summary: "분할계약 요약", published: true)
    base = { category: CATEGORY, severity: "중대", issue: "분할 수의계약 지적.", legal_basis: "지방계약법 시행령 제30조",
             lesson: "분할 금지.", detail: "본문", sector: :common, published: true, topic_slug: @topic.slug }
    # 가상 사례가 가장 최신이어야 «최신 N건» 표면에서 음성대조가 공허하지 않다.
    @simulated = AuditCase.create!(base.merge(title: "F4B 가상 사례", slug: "f4b-sim-case",
                                              source_type: "SILMU_SIMULATED_CASE"))
    @reconstructed = AuditCase.create!(base.merge(title: "F4B 재구성 사례", slug: "f4b-recon-case",
                                                  source_type: "SILMU_RECONSTRUCTED_CASE", is_reconstructed: true))
    @actual = AuditCase.create!(base.merge(title: "F4B 실제 사례", slug: "f4b-actual-case",
                                           source_url: "https://www.goe.go.kr/x.pdf", source_type: "ACTUAL_AUDIT"))
    now = Time.current
    @simulated.update_columns(created_at: now + 3.minutes, updated_at: now + 3.minutes)
    @actual.update_columns(created_at: now + 2.minutes, updated_at: now + 2.minutes)
    @reconstructed.update_columns(created_at: now + 1.minute, updated_at: now + 1.minute)
  end

  # haystack = 응답 본문(String) 또는 slug 배열 — 둘 다 include? 로 판정한다.
  def assert_surface(haystack, label)
    assert haystack.include?(@actual.slug), "#{label} POSITIVE CONTROL: 실제 사례가 빠졌다"
    refute haystack.include?(@simulated.slug), "#{label}: 가상(SIMULATED) 사례가 노출된다"
  end

  test "home: recent audit case cards exclude simulated" do
    get root_url
    assert_response :success
    assert_surface response.body, "home"
  end

  test "RSS feed excludes simulated" do
    get feed_url(format: :rss)
    assert_response :success
    assert_surface response.body, "feed"
    assert_includes response.body, @reconstructed.slug, "feed POSITIVE CONTROL: 재구성 사례가 빠졌다"
  end

  test "llms-full.txt excludes simulated" do
    get llms_full_url
    assert_response :success
    assert_surface response.body, "llms-full"
    assert_includes response.body, @reconstructed.slug, "llms-full POSITIVE CONTROL: 재구성 사례가 빠졌다"
  end

  test "IndexNow submission excludes simulated" do
    urls = SitemapPingJob.new.send(:collect_urls)
    assert_surface urls.join("\n"), "indexnow"
    assert_includes urls, "https://silmu.kr/audit-cases/#{@reconstructed.slug}"
  end

  test "audit case show: same-category list excludes simulated" do
    host = AuditCase.create!(title: "F4B 상세 호스트", slug: "f4b-host-case", category: CATEGORY, severity: "보통",
                             issue: "호스트.", legal_basis: "지방계약법", lesson: "교훈.", detail: "본문",
                             sector: :common, published: true, source_type: "SILMU_RECONSTRUCTED_CASE")
    get audit_case_url(host.slug)
    assert_response :success
    related = response.body[/유사 감사사례.*/m].to_s
    assert related.present?, "«유사 감사사례» 블록이 없다 — 판정이 공허하다"
    assert_surface related, "related_cases"
    assert_includes related, @reconstructed.slug
  end

  test "Topic#related_audit_cases excludes simulated" do
    slugs = @topic.related_audit_cases.map(&:slug)
    assert_surface slugs, "Topic#related_audit_cases"
    assert_includes slugs, @reconstructed.slug
  end
end
