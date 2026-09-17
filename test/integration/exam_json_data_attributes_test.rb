# frozen_string_literal: true

require "test_helper"

# 전수감사 UX TOP#3 — `data-*-value="<%= x.to_json.html_safe %>"` 는 JSON 의 큰따옴표가 속성을 닫아
# 값이 `{` 한 글자로 잘리고, Stimulus 의 JSON.parse 가 실패해 미니 퀴즈가 skeleton 에서 멈췄다.
# 브라우저와 같게 HTML 을 파싱한 뒤 속성값이 JSON 으로 읽히는지 본다.
class ExamJsonDataAttributesTest < ActionDispatch::IntegrationTest
  setup { host! "exam.silmu.kr" }

  def json_attr(path, attr)
    get path
    assert_response :success
    node = Nokogiri::HTML5(response.body).at_css("[#{attr}]")
    assert node, "#{path} 에 #{attr} 속성이 없다"
    JSON.parse(node[attr])
  end

  test "미니 퀴즈 chapter map 과 문제 목록이 JSON 으로 읽힌다" do
    map = json_attr("/quiz/mini", "data-exam-quiz-chapter-map-value")
    assert_kind_of Hash, map
    assert_not_empty map
    assert_kind_of Array, json_attr("/quiz/mini", "data-exam-quiz-questions-value")
  end

  test "북마크 chapter map 이 JSON 으로 읽힌다" do
    map = json_attr("/quiz/bookmarks", "data-exam-quiz-chapter-map-value")
    assert_kind_of Hash, map
    assert_not_empty map
  end

  test "키워드 플래시카드 데이터가 JSON 으로 읽힌다" do
    cards = json_attr("/keywords", "data-exam-flashcard-cards-value")
    assert_kind_of Array, cards
  end
end
