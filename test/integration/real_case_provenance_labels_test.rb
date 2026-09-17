require "test_helper"

# «실제 감사 지적 사례» 라벨이 출처 없는 예시·재구성 사례에 붙던 회귀 (2026-09-17 G-37).
class RealCaseProvenanceLabelsTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  def guide_with_case(slug)
    Guide.new(slug: slug, title: "여비 가이드", published: true, series: "여비_완전정복", series_order: 99,
              sections: { "hook" => "훅", "real_case" => "B 교육청 담당자가 여비를 잘못 받았습니다." }).tap { |g| g.save!(validate: false) }
  end

  def audit_case(slug, type)
    AuditCase.create!(title: "사례 #{slug}", slug: slug, category: "계약", severity: "보통", issue: "지적",
                      published: true, sector: :common, source_type: type)
  end

  test "NORMAL: guide real_case block is labelled as an example, not an actual audit finding" do
    guide_with_case("label-guide-normal")
    get "/guides/label-guide-normal"
    assert_response :success
    assert_includes response.body, "감사 지적 유형 예시"
    assert_not_includes response.body, "실제 감사 지적 사례"
    assert_includes response.body, "B 교육청 담당자가 여비를 잘못 받았습니다."
  end

  test "EDGE: RSS title says «실제» only for ACTUAL_AUDIT cases" do
    audit_case("label-actual", "ACTUAL_AUDIT")
    audit_case("label-reconstructed", "SILMU_RECONSTRUCTED_CASE")
    get "/feed.rss"
    assert_response :success
    assert_includes response.body, "사례 label-actual — 실제 감사 지적 사례와 대응 방법"
    assert_includes response.body, "사례 label-reconstructed — 감사 지적 유형과 대응 방법"
  end

  test "LOWER_BOUND: unclassified case is not called actual" do
    audit_case("label-unclassified", nil)
    get "/feed.rss"
    assert_includes response.body, "사례 label-unclassified — 감사 지적 유형과 대응 방법"
  end

  test "UPPER_BOUND: guide without real_case renders no example block" do
    Guide.new(slug: "label-guide-empty", title: "빈 가이드", published: true, series: "여비_완전정복", series_order: 98,
              sections: { "hook" => "훅" }).save!(validate: false)
    get "/guides/label-guide-empty"
    assert_not_includes response.body, "감사 지적 유형 예시"
  end

  test "EXCEPTION: marketing copy no longer claims every case is an actual audit" do
    %w[app/views/welcome_mailer/welcome.html.erb app/views/welcome_mailer/welcome.text.erb
       app/views/exam/home/_premium_cta.html.erb app/views/exam/home/_free_study.html.erb].each do |p|
      assert_no_match(/실제 감사/, Rails.root.join(p).read, p)
    end
  end
end
