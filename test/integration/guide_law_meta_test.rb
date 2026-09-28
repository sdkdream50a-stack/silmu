# frozen_string_literal: true

require "test_helper"

# «관련 법령» 근거 블록 — article·applies_to·checked_on 을 한 줄로, 옛 {name,text,url} 항목은 그대로.
class GuideLawMetaTest < ActionDispatch::IntegrationTest
  setup do
    @guide = Guide.create!(
      slug: "law-meta-render-test", title: "근거 블록 렌더 테스트", category: "예산", published: true,
      sections: {
        "hook" => "테스트",
        "laws" => [
          { "name" => "지방재정법 시행령", "text" => "투자심사 기준", "url" => "https://www.law.go.kr/법령/지방재정법시행령/제41조",
            "article" => "제41조", "applies_to" => "지방자치단체", "checked_on" => "2026-09-29" },
          { "name" => "지방재정법 제7조", "text" => "회계연도 독립", "article" => "제7조①", "checked_on" => "2026-09-29" },
          { "name" => "지방회계법 제29조", "text" => "지출원인행위", "article" => "제29조", "applies_to" => "재무관" },
          { "name" => "옛 항목", "text" => "옛 설명", "url" => "https://www.law.go.kr/법령/지방회계법" },
          { "name" => "링크 없는 옛 항목", "text" => "설명만" },
          "문자열 항목"
        ]
      }
    )
  end

  test "근거 블록 키가 있으면 조문·적용·확인일을 한 줄로 보여준다" do
    get guide_path(@guide.slug)
    assert_response :success
    metas = css_select("#related [data-law-meta]").map { |n| n.text.strip }
    assert_equal [ "제41조 · 적용: 지방자치단체 · 확인 2026-09-29", "제7조① · 확인 2026-09-29", "적용: 재무관" ], metas
    # 이름에 이미 조문이 있으면(«지방회계법 제29조») 조문을 다시 쓰지 않는다
    assert_not metas.any? { |m| m.start_with?("제29조") }
  end

  test "옛 {name,text,url} 항목·문자열 항목은 이전처럼 렌더되고 메타 줄이 없다" do
    get guide_path(@guide.slug)
    assert_select "#related a[href='https://www.law.go.kr/법령/지방회계법']", text: /옛 항목/
    assert_select "#related p", text: "옛 설명"
    assert_select "#related span", text: "링크 없는 옛 항목"
    assert_select "#related span", text: "문자열 항목"
    assert_select "#related li", 6
    assert_select "#related [data-law-meta]", 3
  end
end
