class TopicCommentModerationJob < ApplicationJob
  queue_as :default

  def perform(comment_id)
    comment = TopicComment.find_by(id: comment_id)
    return unless comment && !comment.hidden?

    moderation = TopicComment.moderate_with_ai(comment.body)
    unless moderation["approved"]
      reason = moderation["reason"].presence || "커뮤니티 가이드라인 위반"
      comment.update!(hidden: true)
      Rails.logger.info "[TopicCommentModeration] 댓글 #{comment_id} AI 거부: #{reason}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[TopicCommentModeration] 댓글 #{comment_id} 없음 (이미 삭제됨)"
  end
end
