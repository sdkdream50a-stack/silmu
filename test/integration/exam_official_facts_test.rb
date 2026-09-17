require "test_helper"

# 공공조달관리사 공식 정보 회귀 (2026-09-17 전수감사 P0).
# 출처: 큐넷 jmCd=9777 · 국가기술자격법 시행규칙 합격기준 · 조달청 표준교재 공개(2026.01.16).
#
# 음성 판정("옛 문구가 없다")은 양성대조(새 문구가 있다)와 같은 응답에서만 의미가 있다.
class ExamOfficialFactsTest < ActionDispatch::IntegrationTest
  STALE_PHRASES = [
    "2026년 상반기 (예정)",
    "위 일정은 예상 일정입니다",
    "공무원 가산점 검토 중",
    "가산점 (예정)",
    "채용 우대 (예정)",
    "48개 이상 맞추면",
    "각 과목 60점 이상 취득 시 합격",
    "필기시험과 실기시험 모두 60점 이상",
    "ppi.re.kr",
    "pps.go.kr/kor/bbs/list.do?bbsSn=1044",
    "기획재정부·조달청",
    "2026년 신설 예정으로"
  ].freeze

  test "exam-info shows the announced schedule and official pass rule, not stale claims" do
    host! "exam.silmu.kr"
    get "/exam-info"
    assert_response :success
    body = response.body

    # 양성대조
    assert_includes body, "2026.09.14(월) 10:00 ~ 09.17(목) 18:00"
    assert_includes body, "2026.11.14(토)"
    assert_includes body, "매 과목 40점 이상, 전 과목 평균 60점 이상"
    assert_includes body, ExamSchedule::SOURCE_URL.gsub("&", "&amp;")
    assert_includes body, "공공조달과 법제도 이해"

    STALE_PHRASES.each { |phrase| assert_not_includes body, phrase, "옛 문구 잔존: #{phrase}" }
  end

  test "strategy page no longer states a raw correct-count pass rule" do
    host! "exam.silmu.kr"
    get "/exam-strategy"
    assert_response :success
    assert_includes response.body, "매 과목 40점 이상, 평균 60점 이상"
    assert_not_includes response.body, "48개 이상 맞추면"
  end

  test "exam home hero carries every exam date for client-side D-day selection" do
    host! "exam.silmu.kr"
    travel_to Time.zone.local(2026, 9, 17, 12) do
      get "/"
    end
    assert_response :success
    assert_includes response.body, "2026-10-03"
    assert_includes response.body, "2026-11-14"
    assert_not_includes response.body, "Official Prep"
    assert_not_includes response.body, "new Date('2026-10-03"
  end

  test "exam home hides the D-day card once every exam has passed" do
    host! "exam.silmu.kr"
    travel_to Time.zone.local(2026, 11, 15, 12) do
      get "/"
    end
    assert_response :success
    assert_not_includes response.body, 'id="dday-wrapper"'
  end
end

class ExamScheduleTest < ActiveSupport::TestCase
  test "NORMAL: before the written exam the written exam is next" do
    assert_equal "written", ExamSchedule.next_exam(Date.new(2026, 9, 17))[:key]
    assert_equal 16, ExamSchedule.days_until_next_exam(Date.new(2026, 9, 17))
  end

  test "LOWER_BOUND: exam day itself counts as D-0 for that exam" do
    assert_equal "written", ExamSchedule.next_exam(Date.new(2026, 10, 3))[:key]
    assert_equal 0, ExamSchedule.days_until_next_exam(Date.new(2026, 10, 3))
  end

  test "EDGE: the day after the written exam switches to the practical exam" do
    assert_equal "practical", ExamSchedule.next_exam(Date.new(2026, 10, 4))[:key]
    assert_equal 41, ExamSchedule.days_until_next_exam(Date.new(2026, 10, 4))
  end

  test "UPPER_BOUND: after the practical exam there is no next exam" do
    assert_nil ExamSchedule.next_exam(Date.new(2026, 11, 15))
    assert_nil ExamSchedule.days_until_next_exam(Date.new(2026, 11, 15))
  end

  test "EXCEPTION: exams are sorted so the first match is the nearest" do
    dates = ExamSchedule::EXAMS.map { |e| e[:on] }
    assert_equal dates.sort, dates
  end
end

class ExamReminderMailerTest < ActionMailer::TestCase
  def build_mail
    user = User.new(email: "tester@example.com")
    progress = ExamProgress.new(streak_count: 3, wrong_answers: [])
    progress.updated_at = 2.days.ago
    ExamReminderMailer.reminder(user, progress)
  end

  test "before the written exam the subject names the written exam D-day" do
    travel_to Time.zone.local(2026, 9, 17, 12) do
      mail = build_mail
      assert_includes mail.subject, "필기시험까지 D-16"
      assert_includes mail.text_part.body.to_s, "필기시험까지 D-16"
    end
  end

  test "between exams the subject switches to the practical exam" do
    travel_to Time.zone.local(2026, 10, 10, 12) do
      assert_includes build_mail.subject, "실기시험까지 D-35"
    end
  end

  test "after every exam there is no frozen D-0" do
    travel_to Time.zone.local(2026, 12, 1, 12) do
      mail = build_mail
      assert_not_includes mail.subject, "D-"
      assert_not_includes mail.text_part.body.to_s, "D-0"
    end
  end
end
