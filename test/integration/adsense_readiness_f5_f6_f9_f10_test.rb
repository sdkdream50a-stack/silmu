require "test_helper"

# 2026-10-05 AdSense 준비도 감사 (하네스 ADSENSE_READINESS_1005.md) F5·F6·F9·F10 회귀.
# 각 항목은 양성 대조(바뀌어야 하는 것)와 음성 대조(그대로여야 하는 것)를 함께 둔다.
class AdsenseReadinessF5F6F9F10Test < ActionDispatch::IntegrationTest
  BASE_CASE = { category: "수의계약", severity: "보통", issue: "분할 수의계약 지적.",
                legal_basis: "지방계약법 시행령 제30조", lesson: "분할 금지.", sector: :common, published: true }.freeze

  def create_case(slug, attrs = {})
    AuditCase.create!(BASE_CASE.merge(title: slug, slug: slug).merge(attrs))
  end

  # ── F5: /about 감사사례 수치 ─────────────────────────────

  test "F5 provenance_breakdown counts each source kind from the ledger" do
    AuditCase.delete_all
    2.times { |i| create_case("f5-actual-#{i}", source_type: "ACTUAL_AUDIT", source_url: "https://example.go.kr/a#{i}.pdf") }
    create_case("f5-actual-no-url", source_type: "ACTUAL_AUDIT") # 원문 URL 없으면 «실제»로 세지 않는다
    3.times { |i| create_case("f5-recon-#{i}", source_type: "SILMU_RECONSTRUCTED_CASE") }
    4.times { |i| create_case("f5-sim-#{i}", source_type: "SILMU_SIMULATED_CASE") }
    create_case("f5-unpublished-sim", source_type: "SILMU_SIMULATED_CASE", published: false)

    assert_equal({ actual: 2, reconstructed: 3, simulated: 4, other: 1 }, AuditCase.published.provenance_breakdown)
  end

  test "F5 about shows the three kinds separately and no blanket 검증 완료 count" do
    AuditCase.delete_all
    create_case("f5-a", source_type: "ACTUAL_AUDIT", source_url: "https://example.go.kr/a.pdf", last_verified_at: Time.current)
    2.times { |i| create_case("f5-r-#{i}", source_type: "SILMU_RECONSTRUCTED_CASE", last_verified_at: Time.current) }
    3.times { |i| create_case("f5-s-#{i}", source_type: "SILMU_SIMULATED_CASE", last_verified_at: Time.current) }

    get "/about"
    assert_response :success
    body = response.body

    # 양성: 종류별 건수가 DB 에서 렌더된다
    assert_includes body, "실제 공개 감사결과 기반 1건"
    assert_includes body, "공식자료 기반 재구성 2건"
    assert_includes body, "예방교육용 가상 시나리오 3건"
    # 음성: last_verified_at 기반 «검증 완료 N건»과 «모든 조문» 과장 문구는 사라진다
    assert_no_match(/검증 완료 \d+건/, body)
    refute_includes body, "모든 조문·수치를"
    refute_includes body, "「검증 완료 · 검토일」"
    # 법령 검증의 범위를 사실관계 검증과 구분해 밝힌다
    assert_includes body, "사례의 사실관계를 검증한 것이 아닙니다"
    # 음성: «기타» 줄은 해당 건이 없으면 나오지 않는다
    refute_includes body, "기타·출처 확인 중"
  end

  test "F5 about shows an other bucket only when such cases exist" do
    AuditCase.delete_all
    create_case("f5-unverified", source_type: "UNVERIFIED")
    get "/about"
    assert_includes response.body, "기타·출처 확인 중 1건"
  end

  # ── F6: 양식 상세 noindex · sitemap ─────────────────────

  test "F6 template detail without a real file is noindex and out of the sitemap" do
    get "/templates/1"
    assert_response :success
    assert_match(/<meta name="robots" content="noindex, follow"/, response.body)

    host! "silmu.kr"
    get "/sitemap.xml"
    assert_response :success
    assert_no_match(%r{<loc>https://silmu\.kr/templates/\d+</loc>}, response.body)
    # 음성: 양식 목록 페이지는 그대로 sitemap 에 남는다
    assert_includes response.body, "<loc>https://silmu.kr/templates</loc>"
  end

  test "F6 template with a real file stays indexable and listed" do
    # public/ 에 파일을 쓰지 않는다 — 병렬 실행되는 TemplateDownloadHonestyTest 가 public/ 의 서식 파일 0개를 전제로 한다.
    # 파일 존재 판정 자체는 아래 downloadable? 단위 테스트가 실제 파일로 검사한다.
    with_downloadable(->(t) { t[:id] == 1 }) do
      get "/templates/1"
      assert_no_match(/<meta name="robots" content="[^"]*noindex/, response.body)
      get "/templates/2"
      assert_match(/<meta name="robots" content="noindex, follow"/, response.body)

      host! "silmu.kr"
      get "/sitemap.xml"
      assert_includes response.body, "<loc>https://silmu.kr/templates/1</loc>"
      refute_includes response.body, "<loc>https://silmu.kr/templates/2</loc>"
    end
  end

  test "F6 downloadable? rejects missing files and traversal paths" do
    refute TemplatesController.downloadable?({ id: 99 })
    refute TemplatesController.downloadable?({ id: 99, files: [ "templates/does-not-exist.hwp" ] })
    refute TemplatesController.downloadable?({ id: 99, files: [ "../Gemfile" ] })
    existing = Dir.children(Rails.root.join("public")).find { |f| Rails.root.join("public", f).file? }
    assert existing, "public/ 에 파일이 하나도 없으면 양성 대조가 공허하다"
    assert TemplatesController.downloadable?({ id: 99, files: [ existing ] })
    assert TemplatesController.downloadable?({ id: 99, files: [ "/#{existing}" ] })
  end

  # ── F10: school-office sitemap ─────────────────────────

  test "F10 sitemap lists the school-office hub and calendar" do
    host! "silmu.kr"
    get "/sitemap.xml"
    assert_includes response.body, "<loc>https://silmu.kr/school-office</loc>"
    assert_includes response.body, "<loc>https://silmu.kr/school-office/calendar</loc>"
  end

  # ── F9: 빈약한 카테고리 hub noindex ────────────────────

  test "F9 category hub with fewer than 3 topics is noindex, with 3 or more it stays indexable" do
    Topic.create!(name: "기타 1", slug: "f9-other-1", category: "other", summary: "s", published: true)
    get "/topics/other"
    assert_response :success
    assert_match(/<meta name="robots" content="noindex, follow"/, response.body)

    3.times { |i| Topic.create!(name: "예산 #{i}", slug: "f9-budget-#{i}", category: "budget", summary: "s", published: true) }
    get "/topics/budget"
    assert_response :success
    assert_no_match(/<meta name="robots" content="[^"]*noindex/, response.body)
  end

  private

  def with_downloadable(predicate)
    original = TemplatesController.method(:downloadable?)
    TemplatesController.define_singleton_method(:downloadable?) { |t| predicate.call(t) }
    yield
  ensure
    TemplatesController.define_singleton_method(:downloadable?, original)
  end
end
