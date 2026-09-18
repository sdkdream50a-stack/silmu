# frozen_string_literal: true

require "test_helper"

# 요구서 §7·§8 (P1-4 확장) — 외부 AI 로 데이터를 보내는 **모든** 도구에 고지가 있는가.
#
# P1-4 는 /ai-assistant 만 고쳤다. 그런데 quote-review·quote-auto 는 **비로그인**으로
# 파일 자체를 api.anthropic.com 에 올리고, 견적서에는 사업자등록번호·담당자 이름·연락처·
# 계좌번호가 들어 있다. 실측 결과 이 세 도구의 경고는 **0** 이었다.
#
# 이 테스트는 «어떤 뷰가 Anthropic 을 쓰는가» 를 코드에서 찾아 그 목록을 강제한다 —
# 도구가 늘어나면 목록을 손으로 고치지 않아도 같이 잡힌다.
class AiToolPrivacyNoticeTest < ActionDispatch::IntegrationTest
  EXTERNAL_AI_TOOLS = {
    "/tools/quote-review"      => "업로드한 견적서 파일",
    "/tools/quote-auto"        => "업로드한 견적서 파일",
    "/tools/official-document" => "작성한 내용",
    "/ai-assistant"            => nil # 자체 문구(P1-4)
  }.freeze

  test "외부 AI 로 보내는 도구에 전송 고지와 AI 역할 한계가 있다" do
    EXTERNAL_AI_TOOLS.each_key do |path|
      get path
      assert_response :success, "#{path} 가 열리지 않는다"
      body = response.body

      assert body.include?("외부 AI(Anthropic)"),
             "#{path} 에 외부 전송 고지가 없다"
      assert body.include?("판단과 확인은 담당자와 원문"),
             "#{path} 에 AI 역할 한계 표시가 없다"
    end
  end

  test "파일 업로드 도구는 «파일» 기준으로 경고한다" do
    %w[/tools/quote-review /tools/quote-auto].each do |path|
      get path
      assert response.body.include?("계좌번호"),
             "#{path} 경고가 파일 내용(계좌번호 등)을 짚지 않는다"
      assert response.body.include?("필요한 부분만 가려서 올리세요"),
             "#{path} 에 실행 가능한 지시가 없다"
    end
  end

  test "경고가 입력 수단보다 앞에 온다" do
    # 올린 뒤에 읽는 경고는 경고가 아니다.
    { "/tools/quote-review" => 'id="file-input"',
      "/tools/quote-auto"   => 'id="qd-file-input"',
      "/tools/official-document" => 'id="od-content-summary"' }.each do |path, input_marker|
      get path
      body = response.body
      notice_at = body.index("외부 AI(Anthropic)")
      input_at  = body.index(input_marker)
      assert notice_at && input_at, "#{path} 에서 경고 또는 입력 수단을 찾지 못했다"
      assert notice_at < input_at, "#{path} 의 경고가 입력 수단 뒤에 있다"
    end
  end

  test "경고가 드롭존 클릭 영역 안에 있지 않다" do
    # 드롭존은 onclick 으로 전체가 파일 선택을 연다. 경고를 그 안에 넣으면
    # 경고를 읽으려고 누른 사용자에게 파일 선택창이 뜬다(초안에서 실제로 그랬다).
    get "/tools/quote-review"
    body = response.body
    zone_at   = body.index('id="upload-zone"')
    notice_at = body.index("외부 AI(Anthropic)")
    assert notice_at < zone_at, "경고가 드롭존 안에 들어갔다"
  end

  test "외부로 보내지 않는 계산기에는 이 고지를 붙이지 않는다" do  # 음성 대조
    get "/tools/overtime-calculator"
    assert_response :success
    assert_not response.body.include?("외부 AI(Anthropic)"),
             "외부 전송이 없는 도구까지 전송 고지가 붙었다"
  end
end
