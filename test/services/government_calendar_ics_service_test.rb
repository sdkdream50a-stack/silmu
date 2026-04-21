require "test_helper"

class GovernmentCalendarIcsServiceTest < ActiveSupport::TestCase
  setup { @ics = GovernmentCalendarIcsService.generate }

  test "RFC 5545 CRLF line ending" do
    # RFC 5545 §3.1 — lines MUST be terminated by CRLF
    first_break = @ics.index("\n")
    assert first_break, "ICS must contain line breaks"
    assert_equal "\r", @ics[first_break - 1],
                 "line endings must be CRLF per RFC 5545"
  end

  test "wraps calendar between BEGIN/END:VCALENDAR" do
    assert @ics.start_with?("BEGIN:VCALENDAR\r\n"),
           "must start with BEGIN:VCALENDAR"
    assert @ics.end_with?("END:VCALENDAR\r\n"),
           "must end with END:VCALENDAR"
  end

  test "has VERSION and PRODID per RFC 5545" do
    # 각 RFC 5545 필수 property는 자체 라인 — CRLF로 구분되므로 분할 후 포함 여부 확인
    lines = @ics.split("\r\n")
    assert_includes lines, "VERSION:2.0"
    assert(lines.any? { |l| l.start_with?("PRODID:") }, "PRODID line required")
  end

  test "every event has required iCalendar properties" do
    events = @ics.scan(/BEGIN:VEVENT.*?END:VEVENT/m)
    assert_operator events.size, :>=, 8,
                    "연간 업무 사이클 이벤트가 최소 8개 등록되어야 함"

    events.each do |event|
      assert_match(/UID:[^\r\n]+@silmu\.kr/, event,
                   "모든 VEVENT에 silmu.kr 도메인 기반 UID 필요")
      assert_match(/SUMMARY:[^\r\n]+/, event)
      assert_match(/DTSTART;VALUE=DATE:\d{8}/, event)
      assert_match(/DTEND;VALUE=DATE:\d{8}/, event)
      assert_match(/RRULE:FREQ=YEARLY/, event,
                   "연간 반복이므로 FREQ=YEARLY 필수")
    end
  end

  test "escapes commas and semicolons in DESCRIPTION per RFC 5545 §3.3.11" do
    # 테스트용 이벤트를 일시적으로 스터빙하는 대신 실제 출력에 "," ";"가 있다면 이스케이프되어야 함
    # 현재 EVENTS 상수에 ","가 다수 포함 → 모든 DESCRIPTION 줄에 \, 형태로 이스케이프되어야 함
    description_lines = @ics.lines.grep(/^DESCRIPTION:/)
    refute_empty description_lines

    description_lines.each do |line|
      # "실무.kr 상세 가이드: https://..."의 ":"은 이스케이프 대상 아님
      # 이스케이프되지 않은 raw "," 검사 — RFC 위반이면 fail
      raw_commas = line.scan(/(?<!\\),/)
      assert_empty raw_commas,
                   "DESCRIPTION에 이스케이프되지 않은 raw 쉼표 — Outlook/Google 파싱 깨짐: #{line.strip}"
    end
  end

  test "UIDs are unique" do
    uids = @ics.scan(/^UID:([^\r\n]+)/).flatten
    assert_equal uids.size, uids.uniq.size, "중복 UID는 중복 이벤트로 인식됨"
  end
end
