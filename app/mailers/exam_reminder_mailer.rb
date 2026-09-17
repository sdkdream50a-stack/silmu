class ExamReminderMailer < ApplicationMailer
  def reminder(user, progress)
    @user = user
    @progress = progress
    @days_absent = ((Time.current - progress.updated_at) / 1.day).to_i
    @streak_count = progress.streak_count
    # wrong_answers는 JSON serialize 적용되어 있으므로 Array로 이미 역직렬화됨
    @wrong_count = Array(progress.wrong_answers).size
    # 시험이 모두 지나면 nil — D-day 를 쓰지 않는다(예전엔 D-0 이 영구 고정됐다).
    @next_exam = ExamSchedule.next_exam
    @days_until_exam = ExamSchedule.days_until_next_exam

    subject = "📚 #{@days_absent}일째 공부를 쉬고 있어요"
    subject += " — 공공조달관리사 #{@next_exam[:label]}까지 D-#{@days_until_exam}" if @next_exam
    mail(to: @user.email, subject: subject)
  end
end
