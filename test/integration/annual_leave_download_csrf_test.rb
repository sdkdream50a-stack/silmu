# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 P1 — 연가 PDF·HWPX 다운로드가 운영에서 422. 도구 화면이 CDN 공개 캐시라 화면 속 CSRF 토큰이
# 방문자 세션과 달랐다. 이 테스트는 CSRF 보호를 켠 채(운영과 같게) 토큰 없는 요청을 보낸다.
class AnnualLeaveDownloadCsrfTest < ActionDispatch::IntegrationTest
  PARAMS = { hire_date: "2020-03-02", ref_year: 2026, used_leave: 3, monthly_wage: 2_500_000 }.freeze

  setup do
    @forgery = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown { ActionController::Base.allow_forgery_protection = @forgery }

  def same_origin = { "Origin" => "http://www.example.com" }

  test "캐시된 화면(토큰 불일치)에서도 같은 출처 요청이면 PDF·HWPX 를 받는다" do
    post "/tools/annual-leave/pdf", params: PARAMS, headers: same_origin
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_operator response.body.bytesize, :>, 1000

    # HWPX 는 파이썬 생성기(로컬 테스트 환경엔 의존성이 없을 수 있음)까지 가면 된다 — CSRF 단계에서 막히지 않았는지만 본다.
    post "/tools/annual-leave/hwpx", params: PARAMS, headers: same_origin
    assert(response.successful? || response.body.include?("HWPX 파일 생성"), "HWPX 요청이 동작에 도달하지 못했다: #{response.status}")
  end

  test "음성 대조 — 다른 출처나 출처 없는 요청은 막는다" do
    post "/tools/annual-leave/pdf", params: PARAMS, headers: { "Origin" => "https://evil.example" }
    assert_response :forbidden
    post "/tools/annual-leave/pdf", params: PARAMS
    assert_response :forbidden
  end
end
