require "test_helper"

class ToolsControllerTest < ActionDispatch::IntegrationTest
  test "tools index returns 200" do
    get tools_url
    assert_response :success
    assert_match(/실무 도구/, response.body, "index 제목 누락")
  end

  # 17개 계산기 액션이 ToolsMeta concern + render_tool_page로 축소됨.
  # 리팩터 회귀 감지용 — 각 라우트가 200 + 고유 title을 실제로 렌더하는지 스모크 테스트.
  # TOOL_METADATA 키 추가/제거 시 이 테스트도 자동으로 검증 범위 확장.
  ToolsMeta::TOOL_METADATA.each do |action_key, meta|
    test "#{action_key} renders 200 with expected title" do
      get public_send("#{action_key}_url")
      assert_response :success

      # title 태그에 TOOL_METADATA의 title이 들어가는지 확인 (meta-tags gem이
      # "... | 실무.kr" 형태로 suffix 붙이므로 부분 매치)
      assert_includes response.body, meta[:title],
                      "#{action_key} 페이지 title이 TOOL_METADATA와 불일치"
      # JSON-LD tool_name도 함께 렌더되는지 (SEO 회귀 방지)
      assert_includes response.body, meta[:tool_name],
                      "#{action_key} JSON-LD tool_name 누락"
    end
  end

  test "task_calendar_ics returns valid iCalendar file" do
    get task_calendar_ics_url
    assert_response :success
    assert_equal "text/calendar; charset=utf-8", response.headers["Content-Type"]
    assert response.body.start_with?("BEGIN:VCALENDAR\r\n"),
           "ICS 본문이 BEGIN:VCALENDAR로 시작해야 함"
    assert response.body.end_with?("END:VCALENDAR\r\n"),
           "ICS 본문이 END:VCALENDAR로 끝나야 함"
    # Content-Disposition attachment 헤더 확인 (브라우저가 다운로드 트리거)
    assert_match(/attachment/, response.headers["Content-Disposition"])
  end

  test "TOOL_METADATA has all required keys for every entry" do
    required = %i[title description keywords og_title og_description tool_name tool_description]
    ToolsMeta::TOOL_METADATA.each do |action_key, meta|
      required.each do |key|
        assert meta[key].is_a?(String) && !meta[key].empty?,
               "#{action_key} 메타에 #{key} 누락 또는 공백"
      end
    end
  end
end
