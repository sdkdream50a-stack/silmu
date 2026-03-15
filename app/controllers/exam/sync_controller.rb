module Exam
  class SyncController < ApplicationController
    layout false

    # GET /sync — 서버 진도 반환
    def show
      return render json: { signed_in: false } unless user_signed_in?

      progress = ExamProgress.for_user(current_user)
      render json: {
        signed_in: true,
        chapters: progress.chapters || {},
        quizzes: progress.quizzes || {},
        chapter_quizzes: progress.chapter_quizzes || {},
        wrong_answers: progress.wrong_answers || [],
        bookmarks: progress.bookmarks || [],
        streak: {
          count: progress.streak_count,
          lastDate: progress.streak_last_date,
          history: progress.streak_history || []
        }
      }
    end

    # POST /sync — 업로드 (로컬 → 서버)
    def create
      unless user_signed_in?
        return render json: { error: "로그인이 필요합니다." }, status: :unauthorized
      end

      progress = ExamProgress.for_user(current_user)
      # Strong Parameters 적용 (permit! 보안 위험 제거)
      data = params.permit(
        :quiz_completed, :streak_count, :streak_last_date,
        chapters: {}, quizzes: {}, chapter_quizzes: {},
        wrong_answers: [], bookmarks: [], streak_history: []
      ).to_h

      # 챕터: 서버와 로컬의 합집합 (더 많이 방문한 쪽 유지)
      merged_chapters = (progress.chapters || {}).merge(data["chapters"] || {})

      # 퀴즈: 최고점 유지
      merged_quizzes = (progress.quizzes || {}).dup
      (data["quizzes"] || {}).each do |k, v|
        existing = merged_quizzes[k]
        merged_quizzes[k] = v if !existing || v.to_h["pct"].to_i >= existing.to_h["pct"].to_i
      end

      # 챕터 퀴즈도 동일
      merged_cq = (progress.chapter_quizzes || {}).dup
      (data["chapter_quizzes"] || {}).each do |k, v|
        existing = merged_cq[k]
        merged_cq[k] = v if !existing || v.to_h["pct"].to_i >= existing.to_h["pct"].to_i
      end

      # 오답: 합집합
      merged_wrong = ((progress.wrong_answers || []) + (data["wrong_answers"] || [])).uniq

      # 북마크: 합집합
      merged_bookmarks = ((progress.bookmarks || []) + (data["bookmarks"] || [])).uniq

      # 스트릭: 더 높은 count 유지
      local_streak_count = data["streak_count"].to_i
      if local_streak_count >= progress.streak_count
        progress.streak_count = local_streak_count
        progress.streak_last_date = data["streak_last_date"]
        progress.streak_history = data["streak_history"] || []
      end

      # 주간 퀴즈 횟수 카운트
      week_start = Time.zone.today.beginning_of_week.to_s
      if progress.weekly_reset_date != week_start
        progress.weekly_quiz_count = 0
        progress.weekly_reset_date = week_start
      end
      if data["quiz_completed"].present?
        progress.weekly_quiz_count = (progress.weekly_quiz_count || 0) + 1
      end

      progress.update!(
        chapters: merged_chapters,
        quizzes: merged_quizzes,
        chapter_quizzes: merged_cq,
        wrong_answers: merged_wrong,
        bookmarks: merged_bookmarks
      )

      render json: { success: true }
    rescue => e
      Rails.logger.error "SyncController error: #{e.message}"
      render json: { error: "동기화 중 오류가 발생했습니다." }, status: :internal_server_error
    end
  end
end
