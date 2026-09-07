# frozen_string_literal: true

require "test_helper"

# 모의고사 «이어풀기» 서버 저장 회귀.
#
# 문의(2026-09-07, hello@silmu.kr): 로그아웃 후 재로그인하면 풀던 위치가 사라진다.
# 원인은 /sync 가 «완료된» 점수만 다루고 진행 중 위치는 아예 취급하지 않은 것이었다.
# 그래서 여기서 검사하는 것은 «저장된다»가 아니라 **다시 내려온다**는 쪽이다.
class ExamSyncInProgressTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # 세션 쿠키가 domain: ".silmu.kr" 로 고정돼 있어(config/application.rb)
    # 다른 호스트에서는 쿠키가 저장되지 않아 두 번째 요청부터 로그아웃된다
    host! "exam.silmu.kr"
    @user = User.create!(email: "quiz-#{SecureRandom.hex(3)}@silmu.kr", password: "Passw0rd!secure")
    sign_in @user
  end

  def post_sync(payload)
    post "/sync", params: payload, as: :json
  end

  test "진행 중 위치를 올리면 다시 로그인해도 그대로 내려온다" do
    post_sync(in_progress: { "1" => { "current" => 42, "qid" => 777, "total" => 120, "score" => 30, "savedAt" => 1_700_000_000_000 } })
    assert_response :success

    sign_out @user
    sign_in @user

    get "/sync"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 42, body.dig("in_progress", "1", "current")
    assert_equal 777, body.dig("in_progress", "1", "qid")
    assert_equal 30, body.dig("in_progress", "1", "score")
  end

  test "더 오래된 저장분은 최신 위치를 덮어쓰지 않는다" do
    post_sync(in_progress: { "1" => { "current" => 50, "savedAt" => 2_000 } })
    post_sync(in_progress: { "1" => { "current" => 3,  "savedAt" => 1_000 } })

    get "/sync"
    assert_equal 50, JSON.parse(response.body).dig("in_progress", "1", "current")
  end

  test "완료 신고한 퀴즈는 서버에서 지워져 이어풀기로 되살아나지 않는다" do
    post_sync(in_progress: { "1" => { "current" => 50, "savedAt" => 2_000 } })
    get "/sync"
    assert JSON.parse(response.body)["in_progress"].key?("1"), "선행 조건: 저장돼 있어야 한다"

    post_sync(in_progress: {}, in_progress_done: [ "1" ])
    get "/sync"
    assert_empty JSON.parse(response.body)["in_progress"]
  end

  test "다른 퀴즈의 진행 위치는 서로 지우지 않는다" do
    post_sync(in_progress: {
      "1" => { "current" => 10, "savedAt" => 1_000 },
      "2" => { "current" => 20, "savedAt" => 1_000 }
    })
    post_sync(in_progress: {}, in_progress_done: [ "1" ])

    get "/sync"
    in_progress = JSON.parse(response.body)["in_progress"]
    assert_not in_progress.key?("1")
    assert_equal 20, in_progress.dig("2", "current")
  end

  test "비로그인 상태에서는 진행 위치를 저장할 수 없다" do
    sign_out @user
    post_sync(in_progress: { "1" => { "current" => 5, "savedAt" => 1_000 } })
    assert_response :unauthorized
  end
end
