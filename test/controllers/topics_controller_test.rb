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

  # NOTE: 구 "llms txt uses current canonical url references" 테스트는 제거됨.
  # public/llms.txt 정적 파일이 LlmsController#summary 동적 생성으로 대체되면서
  # (운영 DB slug 직접 참조) stale slug 혼입이 구조적으로 불가능해짐.
  # 동적 엔드포인트 검증은 LlmsControllerTest 로 이관.
end
