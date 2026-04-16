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

  test "llms txt uses current canonical url references" do
    llms = Rails.root.join("public/llms.txt").read

    assert_includes llms, "자동화 도구 37개"

    stale_paths = %w[
      /topics/split-order-prohibition
      /topics/bid-disqualification
      /topics/guarantee-exemption
      /topics/private-contract-reason
      /topics/goods-vs-service
      /topics/bid-restriction
      /topics/late-penalty-reduction
      /topics/contract-extension
      /topics/e-bid-troubleshoot
      /guides/1
      /guides/2
      /guides/3
      /guides/4
      /guides/5
      /guides/6
      /guides/7
      /guides/8
      /guides/9
    ]
    stale_paths.each { |path| refute_includes llms, "https://silmu.kr#{path})" }

    current_paths = %w[
      /topics/split-contract-prohibition
      /topics/qualification-failure
      /topics/contract-guarantee-exemption
      /topics/private-contract-justification
      /topics/goods-vs-service-contract
      /topics/bid-participation-restriction
      /topics/penalty-reduction-procedure
      /topics/contract-period-extension
      /topics/e-bidding-error-faq
      /guides/purchase-and-inspection
      /guides/inspection-report
      /guides/estimated-price
      /guides/private-contract-guide
      /guides/bidding-guide
    ]
    current_paths.each { |path| assert_includes llms, "https://silmu.kr#{path}" }
  end
end
