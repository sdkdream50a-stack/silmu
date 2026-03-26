class ExamReminderMailer < ApplicationMailer
  def reminder(user, progress)
    @user = user
    @progress = progress
    @days_absent = ((Time.current - progress.updated_at) / 1.day).to_i
    @streak_count = progress.streak_count
    # wrong_answers는 JSON serialize 적용되어 있으므로 Array로 이미 역직렬화됨
    @wrong_count = Array(progress.wrong_answers).size
    @days_until_exam = days_until_exam

    mail(
      to: @user.email,
      subject: "📚 #{@days_absent}일째 공부를 쉬고 있어요 — 공공조달관리사 시험까지 D-#{days_until_exam}일"
    )
  end

  private

  def days_until_exam
    target = Date.new(2026, 10, 17)
    [ (target - Time.zone.today).to_i, 0 ].max
  end
end
