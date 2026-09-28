# frozen_string_literal: true

require "test_helper"

# 2026-09-28 감사 — CDN 공개 캐시 공통 원인.
# ① 로그인 사용자 화면이 public 으로 나가 Cloudflare 가 그 사람의 nav(마이페이지·로그아웃)와 세션 CSRF 토큰을
#    모든 방문자에게 돌려줬다(운영 /tools/split-contract-checker 실측 data-user-signed-in="true").
# ② 캐시된 화면의 토큰은 방문자 세션과 달라 분할계약 판정·표준어 검사 POST 가 운영에서 422 였다.
# ③ 업무달력 no-store 는 expires_in 에 덮여 public 1시간으로 나갔다.
class SharedCachePersonalizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PAGES = %w[/tools/salary-calculator /guides /faq /school-office].freeze

  test "로그인 사용자 화면은 공유 캐시에 남지 않는다" do
    PAGES.each do |path|
      sign_in users(:one)
      get path
      assert_equal "no-store", response.headers["Cache-Control"], path
    end
  end

  test "음성 대조 — 비로그인 화면은 계속 공개 캐시한다" do
    PAGES.each do |path|
      get path
      assert_includes response.headers["Cache-Control"], "public", path
    end
  end

  # 시험 사이트 layout 은 로그인 사용자의 이메일 앞부분을 nav 에 찍는다 — 운영 exam.silmu.kr/subjects 캐시본에서 실측.
  test "시험 사이트 로그인 화면도 공유 캐시에 남지 않는다" do
    host! "exam.silmu.kr"
    sign_in users(:one)
    get "/subjects"
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    sign_out :user
    get "/subjects"
    assert_includes response.headers["Cache-Control"], "public"
  end

  test "업무달력은 누구에게나 no-store 다" do
    get "/tools/task-calendar"
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  # Cloudflare 캐시 규칙(요청에 silmu_auth 가 있으면 캐시 우회)의 짝 — 로그인 중에만 표시가 있어야 한다.
  test "로그인 중에는 캐시 우회 표시를 붙이고 로그아웃하면 지운다" do
    host! "silmu.kr" # 표시 쿠키는 세션과 같은 .silmu.kr 도메인이다
    sign_in users(:one)
    get "/tools/salary-calculator"
    assert_equal "1", cookies["silmu_auth"]
    assert_match(/silmu_auth=1;.*httponly/i, Array(response.headers["Set-Cookie"]).join("\n"))

    get "/guides" # 이미 있으면 다시 보내지 않는다
    refute_match(/silmu_auth=/, Array(response.headers["Set-Cookie"]).join("\n"))

    sign_out :user
    get "/guides"
    assert_match(/silmu_auth=;/, Array(response.headers["Set-Cookie"]).join("\n"))
    assert cookies["silmu_auth"].blank?
  end

  test "음성 대조 — 비로그인 공개 화면에는 Set-Cookie 가 없다(공개 캐시 유지)" do
    PAGES.each do |path|
      get path
      assert_nil response.headers["Set-Cookie"], path
      assert_includes response.headers["Cache-Control"], "public", path
    end
  end

  class StatelessPostTest < ActionDispatch::IntegrationTest
    setup do
      @forgery = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
    end

    teardown { ActionController::Base.allow_forgery_protection = @forgery }

    SPLIT = { contract_type: "goods", current_amount: "10000000" }.freeze

    test "캐시된 화면(토큰 불일치)에서도 같은 출처면 분할계약 판정·표준어 검사가 동작한다" do
      post "/tools/split-contract-checker/evaluate", params: SPLIT, headers: { "Origin" => "http://www.example.com" }, as: :json
      assert_response :success
      post "/tools/standard-term-checker", params: { text: "익일까지 제출" }, headers: { "Origin" => "http://www.example.com" }
      assert_response :success
      get "/tools/standard-term-checker"
      assert_response :success
    end

    test "음성 대조 — 다른 출처나 출처 없는 POST 는 막는다" do
      post "/tools/split-contract-checker/evaluate", params: SPLIT, headers: { "Origin" => "https://evil.example" }, as: :json
      assert_response :forbidden
      post "/tools/standard-term-checker", params: { text: "익일까지 제출" }
      assert_response :forbidden
    end
  end
end
