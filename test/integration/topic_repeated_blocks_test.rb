# frozen_string_literal: true

require "test_helper"

# 토픽 간 반복 블록 축소 (2026-11-04) — 계약 토픽 57개의 같은 서식 4개, 직접 연결되지 않은 가이드 본문.
class TopicRepeatedBlocksTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  def create_topic(slug)
    Topic.create!(name: "반복 #{slug}", slug: slug, category: "contract", sector: :common, keywords: "반복확인", published: true)
  end

  def create_guide(slug, **attrs)
    Guide.create!(title: "반복확인 가이드 #{slug}", slug: slug, category: "계약", sector: :common, published: true,
                  sections: { step1: { title: "준비", items: [ "확인" ] } }, **attrs)
  end

  test "서식 매핑은 실제 정적 서식 파일을 가리킨다" do
    TopicsHelper::TOPIC_FORMS.each_value do |form|
      assert File.file?(Rails.public_path.join(form[:path].delete_prefix("/"))), form[:path]
    end
  end

  test "수의계약 토픽은 서식 카드를 싣고, 관련 없는 계약 토픽은 전체 목록 안내만 싣는다" do
    create_topic("private-contract")
    create_topic("subcontract")

    get "/topics/private-contract"
    assert_response :success
    assert_includes response.body, "/forms/수의계약사유서.html"

    get "/topics/subcontract"
    assert_response :success
    assert_not_includes response.body, "/forms/수의계약사유서.html"
    assert_includes response.body, %(data-forms-panel="index-only")
  end

  test "견적서 검토 안내와 공식 서식 링크는 쓰임이 맞는 계약 토픽에만 싣는다" do
    create_topic("private-contract")
    create_topic("estimated-price")
    create_topic("subcontract")

    get "/topics/private-contract"
    assert_includes response.body, "견적서 검토 시스템"
    assert_includes response.body, "공식 서식 다운로드"

    get "/topics/estimated-price"
    assert_not_includes response.body, "견적서 검토 시스템"
    assert_includes response.body, "공식 서식 다운로드"

    get "/topics/subcontract"
    assert_not_includes response.body, "견적서 검토 시스템"
    assert_not_includes response.body, "공식 서식 다운로드"
  end

  test "흐름도가 없는 토픽은 흐름도 탭과 준비 중 문구를 싣지 않고 법령 탭이 열린다" do
    create_topic("rb-no-flow")
    get "/topics/rb-no-flow"
    assert_response :success
    assert_not_includes response.body, %(data-tab="flowchart")
    assert_not_includes response.body, "실무흐름도가 준비 중"
    assert_not_includes response.body, "showTab('flowchart')"
    assert_select %(.tab-panel.active[data-tab="law"])

    Topic.create!(name: "흐름도", slug: "rb-flow", category: "contract", sector: :common, keywords: "반복확인", published: true,
                  flowchart_mermaid: "flowchart TD; A-->B")
    get "/topics/rb-flow"
    assert_includes response.body, %(data-tab="flowchart")
    assert_includes response.body, "showTab('flowchart')"
    assert_select %(.tab-panel.active[data-tab="flowchart"])
  end

  test "직접 연결된 가이드만 실무절차 본문을 싣고, 키워드로 찾은 가이드는 링크만 남긴다" do
    create_topic("rb-direct")
    create_guide("rb-direct-guide", topic_slug: "rb-direct")
    get "/topics/rb-direct"
    assert_response :success
    assert_includes response.body, %(data-tab="procedure")

    create_topic("rb-fuzzy")
    create_guide("rb-fuzzy-guide")
    get "/topics/rb-fuzzy"
    assert_response :success
    assert_not_includes response.body, %(data-tab="procedure")
    assert_includes response.body, "/guides/rb-fuzzy-guide"
  end
end
