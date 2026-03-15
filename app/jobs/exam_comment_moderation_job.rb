class ExamCommentModerationJob < ApplicationJob
  queue_as :default

  def perform(comment_id, question_text = "")
    comment = ExamQuestionComment.find_by(id: comment_id)
    return unless comment && !comment.hidden?

    moderation = ExamQuestionComment.moderate_with_ai(comment.body, question_text)
    unless moderation["approved"]
      reason = moderation["reason"].presence || "커뮤니티 가이드라인 위반"
      comment.update!(hidden: true)
      Rails.logger.info "[CommentModeration] 댓글 #{comment_id} AI 거부: #{reason}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[CommentModeration] 댓글 #{comment_id} 없음 (이미 삭제됨)"
  end
end
