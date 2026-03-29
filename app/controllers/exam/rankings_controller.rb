module Exam
  class RankingsController < ApplicationController
    layout "exam"

    def index
      # 상위 20명 — 복합 점수 기준 (주간 정답수 + 스트릭 보너스)
      # composite_score = weekly_score + streak_count * 5
      @rankings = ExamProgress
        .where("weekly_quiz_count > 0")
        .select("*, (COALESCE(weekly_score, 0) + streak_count * 5) AS composite_score")
        .order("composite_score DESC, weekly_quiz_count DESC")
        .limit(20)
        .map.with_index(1) do |p, rank|
          avg_pct = p.weekly_total.to_i > 0 ? (p.weekly_score.to_f / p.weekly_total * 100).round : nil
          {
            rank: rank,
            name: p.display_name.presence || "조달수험생#{p.user_id}",
            quiz_count: p.weekly_quiz_count,
            streak: p.streak_count,
            weekly_score: p.weekly_score || 0,
            avg_pct: avg_pct,
            composite_score: p.composite_score.to_i
          }
        end

      # 현재 사용자 순위
      if user_signed_in?
        my_progress = ExamProgress.for_user(current_user)
        @my_quiz_count = my_progress.weekly_quiz_count || 0
        @my_weekly_score = my_progress.weekly_score || 0
        @my_composite = @my_weekly_score + (my_progress.streak_count || 0) * 5
        # 단일 COUNT 쿼리로 순위 계산 (복합 점수 기준)
        @my_rank = ExamProgress.where(
          "COALESCE(weekly_score, 0) + streak_count * 5 > ?", @my_composite
        ).count + 1
        @my_display_name = my_progress.display_name.presence || ""
        @my_avg_pct = my_progress.weekly_total.to_i > 0 ? (my_progress.weekly_score.to_f / my_progress.weekly_total * 100).round : nil
      end

      # 다음 월요일까지 남은 일수
      @days_until_reset = (Time.zone.today.next_week(:monday) - Time.zone.today).to_i

      set_meta_tags(
        title: "주간 랭킹 — 이번 주 학습 리더보드",
        description: "공공조달관리사 시험 대비 주간 학습 랭킹. 이번 주 모의고사 응시 횟수 기준으로 실력을 겨루세요.",
        keywords: "공공조달관리사 랭킹, 학습 리더보드, 모의고사 순위",
        og: { image: "https://exam.silmu.kr/icon.png" },
        twitter: { card: "summary" }
      )
    end

    def update_nickname
      unless user_signed_in?
        return render json: { error: "로그인이 필요합니다." }, status: :unauthorized
      end

      name = params[:display_name].to_s.strip
      if name.length < 2 || name.length > 12
        return render json: { error: "닉네임은 2~12자여야 합니다." }, status: :unprocessable_entity
      end

      progress = ExamProgress.for_user(current_user)
      progress.update!(display_name: name)
      render json: { success: true, display_name: name }
    end
  end
end
