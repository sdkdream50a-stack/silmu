# frozen_string_literal: true

require "test_helper"

# P3 — `/school-office/calendar` 화면.
#
# 이 화면의 약속은 «여기 적힌 날짜는 법령에서 나온 것이고, 교육청마다 다른 것은 다르다고 적혀 있다» 다.
# 그래서 검사는 «렌더되는가» 보다 **«무엇을 말하지 않기로 했는가»** 를 더 본다.
class SchoolAccountingCalendarPageTest < ActionDispatch::IntegrationTest
  test "열린다" do
    get school_office_calendar_path
    assert_response :success
    assert_includes response.body, "학교회계 일정"
  end

  test "회계연도를 3월~2월로 적는다" do
    get school_office_calendar_path
    assert_includes response.body, "3월 1일에 시작해 다음 해 2월 말일"
  end

  test "지자체 회계연도 문구가 이 화면에 새어 들어오지 않는다" do  # LOCAL_GOV / SCHOOL 분리
    get school_office_calendar_path
    body = response.body
    %w[1분기\ 결산 3분기\ 결산 불용\ 예산\ 방지].each do |phrase|
      assert_not_includes body, phrase, "지자체 업무달력 문구가 학교회계 면에 있다: #{phrase}"
    end
  end

  test "다음 기한이 D-표기와 근거와 함께 나온다" do
    travel_to Date.new(2026, 9, 20) do
      get school_office_calendar_path
      body = response.body
      assert_includes body, "2026학년도"
      assert_includes body, "집행기"
      assert_includes body, "초·중등교육법 제30조의3제2항"
      assert_match(/D-\d+/, body, "남은 일수 표기가 없다")
      assert_includes body, "2027년 1월 29일", "다음 회계연도 예산안 제출 기한이 없다"
    end
  end

  test "근거 층 배지가 법률과 교육규칙을 구분해 붙는다" do
    get school_office_calendar_path
    body = response.body
    # 배지 문구만 세면 본문에 스쳐 나온 «법률» 두 글자에도 통과한다. 배지 클래스와 함께 센다.
    law_badges  = body.scan(/bg-editorial-navy text-white">\s*법률/).size
    rule_badges = body.scan(/bg-amber-100 text-amber-900">\s*교육규칙/).size
    assert_operator law_badges, :>, 0, "법률 배지가 하나도 없다"
    assert_operator rule_badges, :>, 0, "교육규칙 배지가 하나도 없다"
  end

  test "출납폐쇄가 전국 공통이 아니라고 화면에 적는다" do
    get school_office_calendar_path
    body = response.body
    assert_includes body, "출납폐쇄 시점은 전국 공통이 아닙니다"
    assert_includes body, "11개 교육청"
    assert_includes body, "6개 교육청"
  end

  test "교육청 선택이 그 교육청 규칙만 보여 준다" do
    get school_office_calendar_path(edu: "전남")
    body = response.body
    assert_includes body, "전라남도교육청"
    assert_includes body, "전라남도립학교 회계 규칙"
    assert_includes body, "ordinSeq=1723383"
    assert_includes body, "이 규칙에는 조항이 없습니다", "전남 규칙에 없는 조항을 있는 것처럼 적는다"
  end

  test "다른 교육청을 고르면 다른 규칙이 나온다" do  # 음성 대조 — 항상 같은 값을 뿌리는 화면이면 무의미
    get school_office_calendar_path(edu: "부산")
    assert_includes response.body, "부산광역시 공립 유치원 및 학교 회계 규칙"
    assert_not_includes response.body, "전라남도립학교 회계 규칙"
  end

  test "없는 교육청 코드는 조용히 무시한다" do
    [ "없는곳", "서울'--", "<script>", "" ].each do |bad|
      get school_office_calendar_path(edu: bad)
      assert_response :success, "edu=#{bad} 에서 깨졌다"
      assert_not_includes response.body, "<script>alert"
    end
  end

  # ── 준예산 ─────────────────────────────────────────────────────────────
  test "준예산 다섯 가지를 법률 문언 그대로 싣는다" do
    get school_office_calendar_path
    SchoolAccountingCalendar::PROVISIONAL_BUDGET_ITEMS.each do |item|
      assert_includes response.body, item[:text], "준예산 제#{item[:no]}호가 화면에 없다"
    end
  end

  test "고르기 전에는 판정을 내지 않는다" do
    get school_office_calendar_path
    assert_not_includes response.body, "MATCHED_CATEGORY"
    assert_not_includes response.body, "NOT_MATCHED"
    assert_not_includes response.body, "CHECK_REQUIRED"
  end

  test "해당 호를 고르면 MATCHED_CATEGORY" do
    get school_office_calendar_path(pb_submitted: "1", pb: [ "1", "3" ])
    body = response.body
    assert_includes body, "MATCHED_CATEGORY"
    assert_includes body, "제1호, 제3호"
    assert_not_includes body, "NOT_MATCHED"
  end

  test "아무것도 고르지 않으면 NOT_MATCHED" do
    get school_office_calendar_path(pb_submitted: "1")
    assert_includes response.body, "NOT_MATCHED"
    assert_not_includes response.body, "MATCHED_CATEGORY —"
  end

  test "판단이 어렵다를 고르면 CHECK_REQUIRED 가 다른 선택을 덮는다" do
    get school_office_calendar_path(pb_submitted: "1", pb: [ "2" ], pb_unsure: "1")
    body = response.body
    assert_includes body, "CHECK_REQUIRED"
    assert_not_includes body, "MATCHED_CATEGORY"
    assert_includes body, "대신 분류하지 않습니다"
  end

  test "법률에 없는 호 번호는 받지 않는다" do  # 열거를 늘리지 않는다
    get school_office_calendar_path(pb_submitted: "1", pb: [ "6", "0", "-1", "abc", "3" ])
    body = response.body
    assert_includes body, "제3호"
    assert_not_includes body, "제6호"
    assert_not_includes body, "제0호"
  end

  test "준예산 판정이 적법성 판단으로 넘어가지 않는다" do
    get school_office_calendar_path(pb_submitted: "1", pb: [ "1" ])
    assert_includes response.body, "최종 판단은 담당자와 소속 교육청 지침으로 합니다"
  end

  # ── 말하지 않기로 한 것 ─────────────────────────────────────────────────
  test "학교회계 과목 판정을 하지 않는다고 적는다" do
    get school_office_calendar_path
    assert_includes response.body, "예산과목(세출과목) 판정"
    assert_includes response.body, "학교회계 과목 도구는 없습니다"
  end

  test "법률에 없는 기한을 만들지 않았다고 적는다" do
    get school_office_calendar_path
    assert_includes response.body, "없는 기한을 만들어 적지 않았습니다"
  end

  test "사립학교는 기준이 다르다고 적는다" do
    get school_office_calendar_path
    assert_includes response.body, "사학기관 재무·회계 규칙"
  end

  test "개인정보 경고가 있다" do
    get school_office_calendar_path
    assert_includes response.body, "이름·주민등록번호·급여·학생 정보를 입력하지 마세요"
  end

  # ── 계측·연결 ──────────────────────────────────────────────────────────
  test "기존 next_action_click 을 재사용한다 — 새 이벤트 없음" do
    get school_office_calendar_path
    body = response.body
    assert_includes body, 'data-next-action-topic-slug-value="hub:school-office-calendar"'
    assert_no_match(/gtag\(\s*"event",\s*"(?!next_action_click)/, body, "새 GA4 이벤트가 생겼다")
  end

  test "연결하는 도구는 실제로 라우팅된다" do  # 없는 기능을 있는 것처럼 걸지 않는다
    paths = (2025..2028).flat_map { |y| SchoolAccountingCalendar.milestones(y) }
                        .flat_map(&:related).map { |r| r[:path] }.uniq
    assert paths.any?, "연결된 도구가 하나도 없다"
    paths.each do |path|
      assert Rails.application.routes.recognize_path(path, method: :get),
             "#{path} 가 라우팅되지 않는다"
    end
  end

  test "집행률 연결은 학교회계(3월)로 연다" do
    get school_office_calendar_path
    assert_includes response.body, "/tools/budget-execution-rate?fy=3"
  end

  # ── 허브 연결 ──────────────────────────────────────────────────────────
  test "허브 상단이 지금 시점을 먼저 답한다" do
    travel_to Date.new(2026, 9, 20) do
      get school_office_path
      body = response.body
      assert_includes body, "2026학년도 집행기"
      assert_includes body, "/school-office/calendar"
      assert_match(/D-\d+/, body)
    end
  end

  # 2026-09-20 변형시험 M25 생존 — 배너만 검사하면 허브 카드를 통째로 지워도 통과한다.
  test "허브 예산 축에 학교회계 일정 카드가 있다" do
    assert_includes SchoolOfficeController.all_paths, "/school-office/calendar",
                    "허브에서 학교회계 일정으로 가는 카드가 사라졌다"
    card = SchoolOfficeController::SECTIONS.find { |s| s[:id] == "budget" }[:items]
                                           .find { |i| i[:path] == "/school-office/calendar" }
    assert card, "예산 축이 아니라 다른 축에 놓였다"
    assert_nil card[:tier], "근거가 법률인데 조건부·참고자료로 내려갔다"

    get school_office_path
    assert_includes response.body, 'data-next-action-slot-param="budget:/school-office/calendar"'
  end

  test "허브의 업무 달력 카드는 여전히 지자체 기준이라고 말한다" do  # P0 비회귀
    get school_office_path
    assert_includes response.body, "회계 일정은 지자체 회계연도(1~12월) 기준"
  end

  test "도구 레지스트리에 넣지 않았다" do  # 「도구 39개」 비회귀
    assert_equal 39, ApplicationHelper::ACTIVE_TOOL_COUNT
    get "/tools"
    assert_response :success
    assert_not_includes response.body, "/school-office/calendar",
                        "도구 목록에 학교회계 일정이 등재됐다 — 39 라는 수가 흔들린다"
  end

  test "지자체 업무달력은 그대로 열린다" do  # 기존 도구 비회귀
    get "/tools/task-calendar"
    assert_response :success
    assert_includes response.body, "회계연도 마감"
  end

  # ── 모바일 ─────────────────────────────────────────────────────────────
  test "390px 에서 가로로 넘치는 고정 폭이 없다" do
    get school_office_calendar_path
    body = response.body
    assert_no_match(/style="[^"]*width:\s*\d{3,}px/, body, "고정 픽셀 폭이 있다")
    assert_no_match(/\bmin-w-\[\d{3,}px\]/, body, "390px 를 넘는 최소 폭이 있다")
    assert_not_includes body, "overflow-x-scroll"
  end
end
