# frozen_string_literal: true

# 모의고사 «이어풀기» — 진행 중(미완료) 풀이 위치를 사용자 계정에 붙인다.
#
# 종전에는 진행 상태가 어디에도 저장되지 않아 페이지를 벗어나면 항상 1번 문제로
# 돌아갔다. localStorage 만으로는 로그아웃·기기 변경에서 그대로 사라지므로
# 완료 점수(quizzes)와 같은 층에 둔다.
#
# 형태: { "<quiz_key>" => { "current" =>, "qid" =>, "total" =>, "score" =>, "savedAt" => } }
#
# ADDITIVE ONLY / NULLABLE / NON-DESTRUCTIVE / REVERSIBLE
class AddInProgressToExamProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :exam_progresses, :in_progress, :jsonb, default: {}
  end
end
