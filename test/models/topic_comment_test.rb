require "test_helper"
require "ostruct"

class TopicCommentTest < ActiveSupport::TestCase
  # --- Validations ---

  test "body 5자 미만은 유효하지 않음" do
    comment = TopicComment.new(body: "짧다", topic_slug: "suui-gyeyak")
    refute comment.valid?
    assert comment.errors[:body].any?
  end

  test "body 800자 초과는 유효하지 않음" do
    comment = TopicComment.new(body: "가" * 801, topic_slug: "suui-gyeyak")
    refute comment.valid?
    assert comment.errors[:body].any?
  end

  test "topic_slug 없으면 유효하지 않음" do
    comment = TopicComment.new(body: "계약 관련 질문입니다.")
    refute comment.valid?
    assert comment.errors[:topic_slug].any?
  end

  test "정상 댓글은 유효함" do
    comment = TopicComment.new(body: "수의계약 요건이 궁금합니다.", topic_slug: "suui-gyeyak")
    assert comment.valid?
  end

  # --- moderate_with_ai (Anthropic::Client을 define_singleton_method으로 mock) ---

  test "moderate_with_ai 승인 케이스" do
    with_ai_response('{"approved": true, "reason": null}') do
      result = TopicComment.moderate_with_ai("계약 업무에서 수의계약 요건이 어떻게 되나요?")
      assert result["approved"]
      assert_nil result["reason"]
    end
  end

  test "moderate_with_ai 거부 케이스" do
    with_ai_response('{"approved": false, "reason": "욕설 포함"}') do
      result = TopicComment.moderate_with_ai("테스트 욕설 댓글")
      refute result["approved"]
      assert_equal "욕설 포함", result["reason"]
    end
  end

  test "moderate_with_ai AI 오류 시 승인 처리 (fail-open)" do
    original_new = Anthropic::Client.method(:new)
    error_client = Object.new
    error_client.define_singleton_method(:messages) { |**_| raise "API 오류" }
    Anthropic::Client.define_singleton_method(:new) { |**_| error_client }
    result = TopicComment.moderate_with_ai("테스트")
    Anthropic::Client.define_singleton_method(:new, original_new)

    assert result["approved"]
  end

  test "moderate_with_ai 잘못된 JSON 응답 시 승인 처리" do
    with_ai_response("잘못된 응답 (JSON 아님)") do
      result = TopicComment.moderate_with_ai("테스트")
      assert result["approved"]
    end
  end

  # --- Scopes ---

  test "visible 스코프는 hidden 댓글 제외" do
    visible = TopicComment.create!(body: "보이는 댓글입니다.", topic_slug: "suui-gyeyak")
    hidden  = TopicComment.create!(body: "숨겨진 댓글입니다.", topic_slug: "suui-gyeyak", hidden: true)

    list = TopicComment.visible.where(topic_slug: "suui-gyeyak")
    assert_includes list, visible
    refute_includes list, hidden
  ensure
    visible&.destroy
    hidden&.destroy
  end

  private

  def with_ai_response(text)
    stub_response = OpenStruct.new(content: [ OpenStruct.new(text: text) ])
    stub_client = Object.new
    stub_client.define_singleton_method(:messages) { |**_| stub_response }
    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { |**_| stub_client }
    yield
  ensure
    Anthropic::Client.define_singleton_method(:new, original_new)
  end
end
