module Exam
  class RankingsController < ApplicationController
    layout "exam"

    def index
      # 상위 20명 (주간 퀴즈 횟수 기준)
      @rankings = ExamProgress
        .where("weekly_quiz_count > 0")
        .order(weekly_quiz_count: :desc)
        .limit(20)
        .map.with_index(1) do |p, rank|
          {
            rank: rank,
            name: p.display_name.presence || "조달수험생#{p.user_id}",
            quiz_count: p.weekly_quiz_count,
            streak: p.streak_count
          }
        end

      # 현재 사용자 순위
      if user_signed_in?
        my_progress = ExamProgress.for_user(current_user)
        my_rank_record = ExamProgress.where("weekly_quiz_count > ?", my_progress.weekly_quiz_count || 0).count
        @my_rank = my_rank_record + 1
        @my_quiz_count = my_progress.weekly_quiz_count || 0
      end

      # 다음 월요일까지 남은 일수
      @days_until_reset = (Time.zone.today.next_week(:monday) - Time.zone.today).to_i

      set_meta_tags(
        title: "주간 랭킹 — 이번 주 학습 리더보드",
        description: "공공조달관리사 시험 대비 주간 학습 랭킹. 이번 주 모의고사 응시 횟수 기준으로 실력을 겨루세요.",
        keywords: "공공조달관리사 랭킹, 학습 리더보드, 모의고사 순위"
      )
    end
  end
end
