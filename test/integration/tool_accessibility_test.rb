# frozen_string_literal: true

require "test_helper"

# PHASE A / 17_UIUX_PERSONA_AUDIT TOP4·TOP8 — 도구 폼 접근성.
#
# 계약방식 도구는 이 사이트의 대표 도구인데 선택 칩 21개가 `span`/`div` + onclick 이라
# **마우스 말고는 조작할 수 없었다**. 초과근무 3 · 여비 4 입력에는 label 연결이 없어
# 스크린리더가 «무엇을 넣는 칸인지» 읽지 못했다.
#
# 이 테스트는 «접근성 점수» 같은 것을 재지 않는다. 구체적으로 무엇이 없었는지만 본다.
class ToolAccessibilityTest < ActionDispatch::IntegrationTest
  CHIP_CLASSES = %w[scope-option type-option type-sub-option special-option].freeze

  test "계약방식 선택 칩이 키보드로 조작 가능한 button 이다" do
    get contract_method_url
    assert_response :success
    body = response.body

    CHIP_CLASSES.each do |cls|
      # span/div 로 남은 칩이 하나도 없어야 한다
      leftover = body.scan(/<(?:span|div) class="#{cls}"/).size
      assert_equal 0, leftover, "#{cls} 칩 #{leftover}개가 아직 span/div 다 — 키보드로 못 누른다"
    end

    buttons = body.scan(/<button type="button" class="(?:#{CHIP_CLASSES.join('|')})"/).size
    assert_equal 21, buttons, "칩 button 이 21개가 아니다(현재 #{buttons}) — 변환에서 빠진 것이 있다"
  end

  test "칩이 선택 상태를 보조기기에 전달한다" do
    get contract_method_url
    body = response.body

    # 초기 상태는 전부 눌리지 않음
    assert_equal 21, body.scan(/aria-pressed="false"/).size,
                 "aria-pressed 초기값이 21개가 아니다"
    # 클래스 변화를 따라가는 동기화가 실려 있는가(함수마다 손으로 넣으면 빠뜨린다)
    assert body.include?("MutationObserver"),
           "선택 상태 동기화가 없다 — 클래스만 바뀌고 낭독은 그대로다"
  end

  test "button 기본 스타일 중화와 포커스 표시가 있다" do
    get contract_method_url
    body = response.body
    assert body.include?("appearance: none"),
           "button 기본 스타일 중화가 없다 — 같은 클래스인데 화면이 달라진다"
    assert body.include?(":focus-visible"),
           "키보드 포커스 표시가 없다 — 키보드로 누를 수는 있는데 어디 있는지 안 보인다"
  end

  test "결과 영역이 sticky 헤더에 가리지 않고 갱신을 알린다" do
    get contract_method_url
    body = response.body
    assert body.include?("scroll-margin-top: 80px"),
           "결과로 스크롤할 때 sticky nav 가 제목을 덮는다"
    assert body.include?('aria-live="polite"'),
           "결과가 바뀌어도 보조기기에 아무 말도 하지 않는다"
  end

  test "초과근무 숫자 입력 3개에 label 이 연결돼 있다" do
    get overtime_calculator_url
    body = response.body
    %w[overtime-hours night-hours holiday-days].each do |id|
      assert body.include?(%(<label for="#{id}")), "#{id} 에 label 연결이 없다"
      assert body.include?(%(id="#{id}")), "#{id} 입력이 사라졌다"
    end
  end

  test "여비 입력 4개에 label 이 연결돼 있다" do
    get travel_calculator_url
    body = response.body
    %w[departure destination start_date end_date].each do |id|
      assert body.include?(%(<label for="#{id}")), "#{id} 에 label 연결이 없다"
    end
  end

  test "label for 가 실재하는 id 를 가리킨다" do  # 양성 대조 — 오타로 허공을 가리키지 않는가
    [ [ contract_method_url, [] ],
      [ overtime_calculator_url, %w[overtime-hours night-hours holiday-days grade-select] ],
      [ travel_calculator_url, %w[departure destination start_date end_date] ] ].each do |url, ids|
      get url
      ids.each do |id|
        assert response.body.include?(%(id="#{id}")),
               "#{url} 의 label 이 존재하지 않는 id=#{id} 를 가리킨다"
      end
    end
  end
end
