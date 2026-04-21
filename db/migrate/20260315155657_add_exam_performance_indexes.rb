class AddExamPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # 랭킹 ORDER BY weekly_quiz_count DESC (매주 랭킹 페이지 조회)
    add_index :exam_progresses, :weekly_quiz_count,
              name: "idx_exam_progresses_on_weekly_quiz_count"

    # 댓글 복합 인덱스: question_id + hidden + likes_count (by_question 스코프)
    add_index :exam_question_comments, [ :question_id, :hidden, :likes_count ],
              name: "idx_exam_comments_on_qid_hidden_likes"

    # 오류 제보 조회용
    add_index :exam_question_reports, :question_id,
              name: "idx_exam_question_reports_on_qid"
  end
end
