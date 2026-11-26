require "test_helper"

# 2026-11-26 — 제1회(실기 2026.11.14) 종료 후 첫 화면이 지난 회차를 앞으로 열릴 시험처럼 안내하지 않는다.
# 출처: 큐넷 시험일정(jmCd=9777, crf00503s02) — 최종합격자 발표 2026.12.18 09:00, 제2회 이후 공고 없음.
class ExamHomeAfterFirstRoundTest < ActionDispatch::IntegrationTest
  OLD_PHRASES = [
    "2026년 첫 시험 준비 중",
    "2026 제1회 시험 대비",
    "2026 첫 시험",
    "2026년 첫 시험 준비를 시작하세요",
    "2026년 공공조달관리사 1회 시험 대비"
  ].freeze

  setup { host! "exam.silmu.kr" }

  test "첫 화면·하단·탭 제목에 옛 준비 문구가 없고 실제 학습 버튼이 있다" do
    travel_to Time.zone.local(2026, 11, 26, 12) do
      get "/"
      assert_response :success
      body = response.body
      assert_select "title", "공공조달관리사 시험 대비 | 실무.kr"
      assert_select "h1", text: /공공조달관리사\s*시험 대비/
      assert_includes body, "2026년 신설 국가기술자격"            # 사실은 남긴다
      assert_select "a[href='/subjects']", text: /무료 커리큘럼 시작/, minimum: 2
      assert_select "a[href='/quiz']", text: /모의고사 풀기/, minimum: 2
      OLD_PHRASES.each { |phrase| assert_not_includes body, phrase, "옛 문구 잔존: #{phrase}" }
    end
  end

  test "발표 전에는 제1회 종료와 발표 예정 시각을 보이고 다음 회차 날짜를 만들지 않는다" do
    travel_to Time.zone.local(2026, 11, 26, 12) do
      get "/"
      assert_includes response.body, "제1회 시험 종료"
      assert_includes response.body, "최종 합격자 발표 2026.12.18(금) 09:00 예정"
      assert_includes response.body, "다음 회차 일정은 큐넷 공고 전입니다"
      assert_no_match(/D-\d/, response.body.gsub(/D-<\/span>/, ""))
    end
  end

  test "exam-info 는 제1회 일정 기록을 그대로 두고 발표 시각을 적는다" do
    travel_to Time.zone.local(2026, 11, 26, 12) do
      get "/exam-info"
      body = response.body
      assert_includes body, "2026.09.14(월) 10:00 ~ 09.17(목) 18:00"
      assert_includes body, "2026.11.14(토)"
      assert_includes body, "2026.12.18(금) 09:00"
      assert_includes body, "빈자리 접수 2026.11.08 ~ 11.09"
      assert_includes body, "제2회 이후 시험 일정은 아직 확인되지 않았습니다"
    end
  end
end

class ExamRoundStatusTest < ActiveSupport::TestCase
  test "실기 당일까지는 남은 시험이 있다" do
    assert_equal :upcoming, ExamSchedule.round_status(Time.zone.local(2026, 11, 14, 23, 59))
  end

  test "실기 다음 날부터 발표 직전까지는 발표 대기" do
    assert_equal :awaiting_results, ExamSchedule.round_status(Time.zone.local(2026, 11, 15, 0, 0))
    assert_equal :awaiting_results, ExamSchedule.round_status(Time.zone.local(2026, 12, 18, 8, 59))
  end

  test "발표일 09:00 부터는 발표 완료" do
    assert_equal :results_announced, ExamSchedule.round_status(Time.zone.local(2026, 12, 18, 9, 0))
  end

  test "UTC 로 넘겨도 KST 09:00 기준으로 판정한다" do
    assert_equal :awaiting_results, ExamSchedule.round_status(Time.utc(2026, 12, 17, 23, 59))
    assert_equal :results_announced, ExamSchedule.round_status(Time.utc(2026, 12, 18, 0, 0))
  end
end
