# frozen_string_literal: true

require "test_helper"

# PHASE-LECTURE-P1 batch1 (LECTURE_READINESS_AUDIT P1-2·P1-4·P1-6·P1-7·P1-8·P1-9)
#
# 설계 원칙 — 이 배치의 결함은 전부 «있어야 할 것이 화면·설정에 없다» 였으므로
# 등록부가 아니라 **렌더된 응답 바이트**와 **실제 필터 동작**을 본다.
# 각 테스트는 수리 전 실패를 확인한 뒤 남겼다(양성 대조).
class LectureP1Batch1Test < ActionDispatch::IntegrationTest
  # ── P1-7 : 존재하지 않는 법령명 ────────────────────────────────────────────
  # 「지방공무원 여비 규정」은 law.go.kr 에 없다(2026-09-17 실측 · G-34).
  # 지방공무원 여비는 각 지자체 조례가 정한다. 대체 명칭을 만들지 않고 삭제했다.
  test "여비 도구 신뢰 박스에 존재하지 않는 «지방공무원 여비 규정» 이 없다" do
    trust = YAML.load_file(Rails.root.join("config/tool_trust.yml"))
    # 파싱된 «값» 만 본다 — 주석에는 삭제 사유가 남아 있어야 정상이다.
    assert_not YAML.dump(trust).include?("지방공무원 여비"),
               "tool_trust 값에 존재하지 않는 법령명이 남아 있다"

    get travel_calculator_url
    assert_response :success
    assert_not response.body.include?("지방공무원 여비"),
               "화면에 존재하지 않는 법령명이 렌더된다"
    # 음성 대조 — 실재하는 법령명까지 같이 지워 버리지 않았는가
    assert response.body.include?("공무원 여비 규정"),
           "실재하는 「공무원 여비 규정」까지 사라졌다"
  end

  # ── P1-4 : AI 어시스턴트 개인정보 경고 ─────────────────────────────────────
  test "AI 어시스턴트 입력창 «위»에 개인정보 경고와 AI 역할 표시가 있다" do
    get ai_assistant_url
    assert_response :success
    body = response.body

    assert body.include?("이름·주민등록번호·급여·병가·학생 정보를 입력하지 마세요"),
           "개인정보 입력 금지 경고가 없다"
    assert body.include?("외부 AI(Anthropic)로 전송됩니다"),
           "외부 전송 사실 고지가 없다"
    assert body.include?("판단과 확인은 담당자와 원문"),
           "AI 역할 한계 표시가 없다"

    # 위치 — 경고가 입력창보다 «앞» 에 있어야 한다. 뒤에 있으면 입력한 뒤에 읽는다.
    warn_at  = body.index("이름·주민등록번호·급여·병가·학생 정보를 입력하지 마세요")
    input_at = body.index('data-ai-chat-target="input"')
    assert warn_at && input_at, "경고 또는 입력창을 찾지 못했다"
    assert warn_at < input_at, "경고가 입력창 뒤에 있다 — 입력 전에 읽히지 않는다"
  end

  # ── P1-2 : 계약방식 도구 GA4 계측 ─────────────────────────────────────────
  # URL 은 /tools/contract-method 인데 컨트롤러가 contract_methods 라 계측 파셜이 빠져 있었다.
  test "계약방식 도구에 도구 계측 스크립트가 렌더된다" do
    get contract_method_url
    assert_response :success
    assert response.body.include?("window.silmuCalcResult"),
           "계측 파셜이 렌더되지 않았다(layout 조건에서 빠졌다)"
    assert response.body.include?("calc_complete"),
           "완료 이벤트 정의가 없다"
  end

  test "계측 파셜은 여전히 /tools 도구에 붙는다" do  # 비퇴화
    get overtime_calculator_url
    assert_response :success
    assert response.body.include?("window.silmuCalcResult")
  end

  test "계측이 필요 없는 페이지에는 붙지 않는다" do  # 음성 대조 — 조건을 너무 넓히지 않았는가
    get root_url
    assert_response :success
    assert_not response.body.include?("window.silmuCalcResult")
  end

  # ── P1-6 : 초과근무 모바일 결과 스크롤 ────────────────────────────────────
  test "초과근무 결과 영역에 스크롤 여백이 있고 버튼만 결과로 이동시킨다" do
    get overtime_calculator_url
    assert_response :success
    body = response.body

    assert body.include?('id="result-area" class="card p-6 scroll-mt-20"'),
           "결과 영역에 sticky 헤더만큼의 scroll-margin 이 없다"
    assert body.include?('onclick="calculate({ reveal: true })"'),
           "계산 버튼이 결과 노출을 요청하지 않는다"
    # 입력 중 재계산은 스크롤하면 안 된다 — oninput 은 인자 없이 부른다.
    assert body.include?('oninput="calculate()"'),
           "oninput 경로가 스크롤 인자를 넘기고 있다(타이핑 중 화면이 튄다)"
  end

  # ── P1-8 : Clarity — 수집이 CSP 로 막힌 채 «켜져» 있지 않다 ────────────────
  # 이 불변식은 «태그가 켜져 있으면 CSP 가 그 수집 호스트를 허용해야 한다» 다.
  # 2026-09-18 운영 상태가 정확히 그 위반이었다 — 태그는 뜨고 녹화도 하는데
  # `e.clarity.ms/collect` 가 connect_src 에 없어 전송이 전량 차단됐다(콘솔 오류 4건/페이지).
  # ⚠️ 첫 판본은 «태그가 꺼져 있으면 통과» 로만 써서 수리 전 트리에서도 통과하는
  #    죽은 검사였다. 아래는 수리 전 트리에서 실제로 실패하는 형태다.
  test "Clarity 태그가 켜져 있으면 CSP connect_src 가 수집 호스트를 허용한다" do
    layout = Rails.root.join("app/views/layouts/application.html.erb").read
    csp    = Rails.root.join("config/initializers/content_security_policy.rb").read

    loader_present = layout.include?("clarity.ms/tag/")
    disabled       = layout.match?(/clarity_enabled\s*=\s*false/)

    # connect_src 지시자 «안» 만 본다 — clarity.ms 는 script_src·img_src 에도 있어서
    # 파일 전체를 grep 하면 없는 허용을 있다고 읽는다.
    connect_block = csp[/policy\.connect_src.*?(?=\n\n|\n    policy\.)/m].to_s
    collector_allowed = connect_block.include?("e.clarity.ms") ||
                        connect_block.include?("*.clarity.ms")

    if loader_present && !disabled
      assert collector_allowed,
             "Clarity 태그가 켜져 있는데 connect_src 에 수집 호스트가 없다 — " \
             "녹화는 하고 전송만 차단되는 조용한 고장이다"
    else
      # 꺼 둔 상태가 정본이라면, 켜는 순간 위 분기가 잡도록 로더가 그대로 있어야 한다.
      assert loader_present, "로더 자체가 사라져 이 불변식을 검사할 대상이 없다"
    end
  end

  # ── P1-9 : 검색어·질문·급여 입력 로그 마스킹 ──────────────────────────────
  test "검색어·질문·급여 입력이 로그 파라미터에서 필터된다" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(
      "q" => "우리 학교 병가", "question" => "수의계약 한도",
      "content" => "본문", "memo" => "메모",
      "monthly_wage" => "3000000", "hire_date" => "2020-03-01"
    )
    filtered.each do |k, v|
      assert_equal "[FILTERED]", v, "#{k} 가 로그에 그대로 남는다"
    end
  end

  test "한 글자 키 필터가 무관한 파라미터까지 먹지 않는다" do
    # `filter_parameters` 의 심볼은 **부분일치**다. `:q` 를 그대로 넣으면
    # quantity·quote_id·request_id 까지 전부 [FILTERED] 가 된다(2026-09-18 실측).
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(
      "quantity" => "3", "quote_id" => "7", "request_id" => "abc", "page" => "2"
    )
    assert_equal({ "quantity" => "3", "quote_id" => "7", "request_id" => "abc", "page" => "2" },
                 filtered, "한 글자 키 필터가 과도하게 적용됐다")
  end
end
