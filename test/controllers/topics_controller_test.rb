require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  test "topic meta description uses plain text instead of markdown" do
    topic = Topic.create!(
      name: "마크다운 설명",
      slug: "markdown-description-topic",
      category: "contract",
      summary: "수의계약 요약",
      commentary: "## 수의계약, **편리하지만** 가장 많이 지적됩니다\n\n[지방계약법](https://example.com) 기준으로 확인하세요.",
      keywords: "수의계약",
      published: false
    )

    get topic_url(topic.slug)

    assert_response :success
    description = response.body.match(/<meta name="description" content="([^"]*)"/)[1]
    og_description = response.body.match(/<meta property="og:description" content="([^"]*)"/)[1]

    [ description, og_description ].each do |text|
      assert_includes text, "수의계약"
      assert_includes text, "편리하지만"
      refute_includes text, "##"
      refute_includes text, "**"
      refute_includes text, "["
      refute_includes text, "]("
    end
  end

  test "topic exposes law base date for SEO and AI citation freshness" do
    topic = Topic.create!(
      name: "법령 기준일 테스트",
      slug: "law-base-date-topic",
      category: "contract",
      summary: "법령 기준일 구조화 데이터 확인",
      commentary: "기준일 이후 개정 여부를 확인합니다.",
      keywords: "법령 기준일",
      law_base_date: "2026.03.19",
      published: false
    )

    get topic_url(topic.slug)

    assert_response :success
    assert_includes response.body, '<meta name="law-base-date" content="2026-03-19">'
    assert_includes response.body, '<meta property="article:modified_time"'
    assert_includes response.body, '"contentReferenceTime":"2026-03-19"'
    assert_includes response.body, '"temporalCoverage":"2026-03-19"'
  end

  test "exam subdomain 301 redirects shared topic content to apex silmu.kr" do
    topic = Topic.create!(
      name: "교차 301",
      slug: "cross-host-301-topic",
      category: "contract",
      summary: "요약",
      commentary: "본문",
      keywords: "수의계약",
      published: false
    )

    host! "exam.silmu.kr"
    get "/topics/#{topic.slug}"

    assert_response :moved_permanently
    assert_equal "https://silmu.kr/topics/cross-host-301-topic", response.location
  end

  test "exam subdomain preserves query string on shared content 301" do
    host! "exam.silmu.kr"
    get "/audit-cases?page=2"

    assert_response :moved_permanently
    assert_equal "https://silmu.kr/audit-cases?page=2", response.location
  end

  test "main host serves shared topic content without redirect" do
    topic = Topic.create!(
      name: "메인 무리다이렉트",
      slug: "main-no-redirect-topic",
      category: "contract",
      summary: "요약",
      commentary: "본문",
      keywords: "수의계약",
      published: false
    )

    host! "silmu.kr"
    get "/topics/#{topic.slug}"

    assert_response :success
    canonical = response.body.match(/<link rel="canonical" href="([^"]*)"/)[1]
    assert_equal "/topics/main-no-redirect-topic", URI.parse(canonical).path
    assert_equal "silmu.kr", URI.parse(canonical).host
  end

  test "topic speakable schema uses real selectors and audience is category-neutral" do
    topic = Topic.create!(
      name: "스피커블 셀렉터",
      slug: "speakable-selector-topic",
      category: "duty",
      summary: "복무 토픽 요약",
      commentary: "본문",
      keywords: "특별휴가",
      published: false
    )

    host! "silmu.kr"
    get "/topics/#{topic.slug}"

    assert_response :success
    # quick_stats(핵심 답변 자산)가 speakable에 포함, 죽은 셀렉터는 제거됨
    assert_includes response.body, ".quick-stats"
    refute_includes response.body, ".topic-first-paragraph"
    refute_includes response.body, ".commentary > p:first-child"
    # 복무 토픽 audience가 "계약·재무"로 오기되지 않고 일반화됨
    refute_includes response.body, "계약·재무 담당자"
    assert_includes response.body, "공무원·공공기관 실무 담당자"
  end

  # NOTE: 구 "llms txt uses current canonical url references" 테스트는 제거됨.
  # public/llms.txt 정적 파일이 LlmsController#summary 동적 생성으로 대체되면서
  # (운영 DB slug 직접 참조) stale slug 혼입이 구조적으로 불가능해짐.
  # 동적 엔드포인트 검증은 LlmsControllerTest 로 이관.
end
