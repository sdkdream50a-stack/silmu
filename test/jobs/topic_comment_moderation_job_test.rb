require "test_helper"

class TopicCommentModerationJobTest < ActiveSupport::TestCase
  setup do
    @comment = TopicComment.create!(
      body: "수의계약 관련 질문드립니다.",
      topic_slug: "suui-gyeyak"
    )
  end

  teardown do
    @comment.destroy if @comment.persisted?
  end

  test "AI 승인 시 댓글이 visible 유지됨" do
    with_moderation_result("approved" => true, "reason" => nil) do
      TopicCommentModerationJob.perform_now(@comment.id)
    end

    @comment.reload
    refute @comment.hidden?
  end

  test "AI 거부 시 댓글이 hidden 처리됨" do
    with_moderation_result("approved" => false, "reason" => "스팸") do
      TopicCommentModerationJob.perform_now(@comment.id)
    end

    @comment.reload
    assert @comment.hidden?
  end

  test "이미 hidden인 댓글은 모더레이션 건너뜀" do
    @comment.update!(hidden: true)
    call_count = 0

    original = TopicComment.method(:moderate_with_ai)
    TopicComment.define_singleton_method(:moderate_with_ai) { |_| call_count += 1; { "approved" => false } }
    begin
      TopicCommentModerationJob.perform_now(@comment.id)
    ensure
      TopicComment.define_singleton_method(:moderate_with_ai, original)
    end

    assert_equal 0, call_count
  end

  test "존재하지 않는 comment_id는 예외 없이 무시" do
    assert_nothing_raised do
      TopicCommentModerationJob.perform_now(-9999)
    end
  end

  private

  def with_moderation_result(result, &block)
    original = TopicComment.method(:moderate_with_ai)
    TopicComment.define_singleton_method(:moderate_with_ai) { |_| result }
    block.call
  ensure
    TopicComment.define_singleton_method(:moderate_with_ai, original)
  end
end
