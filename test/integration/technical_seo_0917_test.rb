require "test_helper"

# 기술 SEO 회귀 (2026-09-17 전수감사 G-31·G-43, 18_SEO_TECHNICAL_BASELINE.md 이슈 1·3·4·6·7·8·9)
class TechnicalSeo0917Test < ActionDispatch::IntegrationTest
  def meta_content(attr, name)
    response.body[/<meta #{attr}="#{Regexp.escape(name)}" content="([^"]*)"/, 1]
  end

  # --- 1. twitter:title/description 기본값 → 페이지 자신의 title/description ---

  test "NORMAL: page without explicit twitter tags mirrors its own title and description" do
    host! "silmu.kr"
    get "/templates"

    assert_response :success
    assert_equal "문서 양식 — 계약서·검수조서·기안문 26종 무료 다운로드", meta_content("name", "twitter:title")
    assert_equal meta_content("name", "description"), meta_content("name", "twitter:description")
  end

  test "EDGE: page with explicit twitter values keeps them (topic)" do
    topic = Topic.create!(name: "트위터 명시", slug: "twitter-explicit-topic", category: "contract",
                          summary: "요약", commentary: "본문", keywords: "수의계약", published: false)
    host! "silmu.kr"
    get "/topics/#{topic.slug}"

    assert_response :success
    assert_equal meta_content("property", "og:title"), meta_content("name", "twitter:title")
    refute_equal "실무.kr", meta_content("name", "twitter:title")
  end

  test "EDGE: exam native page mirrors its title into twitter:title" do
    host! "exam.silmu.kr"
    get "/quiz/analysis"

    assert_response :success
    assert_equal "학습 분석 대시보드", meta_content("name", "twitter:title")
    assert_equal meta_content("name", "description"), meta_content("name", "twitter:description")
  end

  # --- 4. trailing slash 정규화 ---

  test "NORMAL: GET non-root path with trailing slash 301s to slashless path" do
    host! "silmu.kr"
    get "/templates/"

    assert_response :moved_permanently
    assert_equal "http://silmu.kr/templates", response.location
  end

  test "NORMAL: trailing slash redirect preserves query string" do
    host! "silmu.kr"
    get "/guides/?page=2&utm_source=x"

    assert_response :moved_permanently
    assert_equal "http://silmu.kr/guides?page=2&utm_source=x", response.location
  end

  test "UPPER: multiple trailing slashes collapse in one hop" do
    host! "silmu.kr"
    get "/tools/contract-method///"

    assert_response :moved_permanently
    assert_equal "http://silmu.kr/tools/contract-method", response.location
  end

  test "LOWER: root path is not redirected" do
    host! "silmu.kr"
    get "/"

    assert_response :success
  end

  test "EDGE: HEAD with trailing slash also 301s, exam host keeps its own host" do
    host! "silmu.kr"
    head "/templates/"
    assert_response :moved_permanently

    host! "exam.silmu.kr"
    get "/quiz/"
    assert_response :moved_permanently
    assert_equal "http://exam.silmu.kr/quiz", response.location
  end

  test "UPPER: exam host + trailing slash on an apex-shared path goes to apex in one hop, and apex target is final" do
    host! "exam.silmu.kr"
    get "/start/?utm_source=qr"
    assert_response :moved_permanently
    assert_equal "https://silmu.kr/start?utm_source=qr", response.location

    get "/topics/private-contract/"
    assert_equal "https://silmu.kr/topics/private-contract", response.location

    host! "silmu.kr"
    get "/start"
    assert_not_equal 301, response.status, "apex 도착지에서 다시 리다이렉트되면 루프·다중 hop"
  end

  test "EXCEPTION: POST with trailing slash and /up health check are not redirected" do
    host! "silmu.kr"
    post "/feedback/", params: {}
    refute_equal 301, response.status

    get "/up"
    assert_response :success
  end

  test "EDGE: canonical_url never ends with a slash except root" do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create(
      "HTTP_HOST" => "silmu.kr", "PATH_INFO" => "/topics/bidding/", "QUERY_STRING" => "a=1"
    )
    assert_equal "http://silmu.kr/topics/bidding", controller.send(:canonical_url)

    root = ApplicationController.new
    root.request = ActionDispatch::TestRequest.create("HTTP_HOST" => "silmu.kr", "PATH_INFO" => "/")
    assert_equal "http://silmu.kr/", root.send(:canonical_url)
  end

  # --- 3. /tools/quote-review 메타 ---

  test "NORMAL: quote-review standalone page has title, description, canonical, og and one h1" do
    host! "silmu.kr"
    get "/tools/quote-review"

    assert_response :success
    assert_includes response.body, "<title>견적서 검토 시스템 | 실무.kr</title>"
    assert meta_content("name", "description").present?
    assert_includes response.body, '<link rel="canonical" href="http://silmu.kr/tools/quote-review">'
    assert_equal meta_content("name", "description"), meta_content("property", "og:description")
    assert meta_content("property", "og:title").present?
    assert_equal "견적서 검토 시스템", meta_content("name", "twitter:title")
    assert_equal 1, response.body.scan(/<h1[\s>]/).size
    assert_includes response.body, "quote-reviews/analyze", "도구 기능(분석 엔드포인트 호출)은 유지"
  end

  # --- 7. sitemap lastmod ---

  test "NORMAL: apex sitemap uses record updated_at and never emits today's date" do
    topic = Topic.create!(name: "lastmod 토픽", slug: "lastmod-topic-0917", category: "contract",
                          summary: "요약", commentary: "본문", keywords: "k", published: true,
                          law_verified_at: nil)
    topic.update_columns(updated_at: Time.zone.local(2025, 5, 5, 12))

    travel_to Time.zone.local(2030, 1, 1, 9) do
      host! "silmu.kr"
      get "/sitemap.xml"
    end

    assert_response :success
    assert_includes response.body, "<loc>https://silmu.kr/topics/lastmod-topic-0917</loc>\n    <lastmod>2025-05-05</lastmod>"
    refute_includes response.body, "<lastmod>2030-01-01</lastmod>"
    refute_match %r{<loc>https://silmu\.kr/tools/contract-method</loc>\s*<lastmod>}, response.body
  end

  test "NORMAL: exam sitemap emits no fake lastmod" do
    host! "exam.silmu.kr"
    get "/sitemap.xml"

    assert_response :success
    refute_includes response.body, "<lastmod>"
  end

  # --- 8. exam sitemap 위생 ---

  test "EXCEPTION: exam sitemap excludes redirecting, noindex and per-user URLs" do
    host! "exam.silmu.kr"
    get "/sitemap.xml"
    body = response.body

    %w[/quiz/4 /rankings /quiz/wrong /quiz/analysis].each do |path|
      refute_includes body, "<loc>https://exam.silmu.kr#{path}</loc>"
    end
    assert_includes body, "<loc>https://exam.silmu.kr/quiz/1</loc>"
  end

  test "UPPER: every /quiz/:id listed in exam sitemap returns 200" do
    host! "exam.silmu.kr"
    get "/sitemap.xml"
    quiz_paths = response.body.scan(%r{<loc>https://exam\.silmu\.kr(/quiz/\d+)</loc>}).flatten
    assert_operator quiz_paths.size, :>=, 1, "과목 모의고사 URL을 못 읽으면 공허"

    quiz_paths.each do |path|
      get path
      assert_response :success, "#{path} 가 200이 아님"
    end
  end

  # --- 9. llms-full.txt 구조 보존 ---

  test "NORMAL: llms-full.txt decodes entities and keeps markdown line structure" do
    Topic.create!(
      name: "llms 구조 토픽", slug: "llms-structure-topic", category: "contract",
      summary: "요약", commentary: "본문", keywords: "k", published: true,
      law_content: "<p>제1조(목적)</p>\n## 금액 기준\n| 항목 | 값 |\n|---|---|\n| 금액 | 2천만원 &gt; 1천만원 |\n\n\n\n끝  \t 공백"
    )

    host! "silmu.kr"
    get "/llms-full.txt"

    assert_response :success
    body = response.body
    assert_includes body, "## 금액 기준\n| 항목 | 값 |\n|---|---|\n| 금액 | 2천만원 > 1천만원 |"
    assert_includes body, "끝 공백"
    refute_includes body, "&gt;"
    refute_includes body, "끝  "
    section = body[/### llms 구조 토픽.*?\n---\n/m]
    refute_match(/\n{3,}/, section.to_s.sub(/\*\*법률\*\*\n/, ""))
  end

  test "EDGE: llms.txt inline summaries decode entities but stay on one line" do
    Topic.create!(name: "llms 인라인 토픽", slug: "llms-inline-topic", category: "contract",
                  summary: "A &amp; B\n둘째 줄", commentary: "본문", keywords: "k", published: true)

    host! "silmu.kr"
    get "/llms.txt"

    assert_response :success
    assert_includes response.body, "- [llms 인라인 토픽](https://silmu.kr/topics/llms-inline-topic): A & B 둘째 줄"
  end

  # --- 6. exam 호스트의 apex 전용 페이지 → apex 301 ---

  test "NORMAL: exam host 301s apex-only pages to apex preserving path and query" do
    host! "exam.silmu.kr"
    %w[/templates /templates/7 /about /updates /start /silmu-search /privacy /terms /contact /feedback].each do |path|
      get path
      assert_response :moved_permanently, path
      assert_equal "https://silmu.kr#{path}", response.location
    end

    get "/silmu-search?q=%EC%88%98%EC%9D%98"
    assert_equal "https://silmu.kr/silmu-search?q=%EC%88%98%EC%9D%98", response.location
  end

  test "EDGE: exam native pages and prefix look-alikes are not sent to apex" do
    host! "exam.silmu.kr"
    get "/quiz"
    assert_response :success

    get "/templatesx"
    refute_equal "https://silmu.kr/templatesx", response.location
  end

  test "LOWER: apex host serves the same pages without redirect" do
    host! "silmu.kr"
    %w[/templates /about /privacy].each do |path|
      get path
      assert_response :success, path
    end
  end
end
