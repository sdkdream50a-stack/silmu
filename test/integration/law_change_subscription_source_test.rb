# frozen_string_literal: true

require "test_helper"

# 리드 글 귀속 (2026-09-14 · silmu-lead-attribution-tool-completion-v1)
# 계약: 구독 행의 source = 착지 글 logNo(utm_content). 모르면 NULL(=UNMEASURED) — 0·캠페인명·추측 금지.
# 법령 개정 알림 구독은 광고성 수신동의(users.newsletter_agreed)가 아니다.
class LawChangeSubscriptionSourceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  POST_ID = "224243216770"

  def subscribe(email: "lead-#{SecureRandom.hex(3)}@example.com", topic: "overtime-allowance", **extra)
    post law_change_subscriptions_path,
         params: { email: email, topic_slug: topic, topic_name: "초과근무수당" }.merge(extra)
    LawChangeSubscription.find_by!(email: email, topic_slug: topic)
  end

  test "T2 source_post(logNo) 가 구독 행 source 로 기록된다" do
    sub = subscribe(source_post: POST_ID)
    assert_equal POST_ID, sub.source
  end

  test "T8 source_post 가 없으면 NULL 로 남는다 — 0 이나 빈 문자열이 아니다" do
    sub = subscribe
    assert_nil sub.source
  end

  test "T8 logNo 형식이 아닌 값(cta_card·캠페인명·0·주입 문자열)은 NULL" do
    [ "cta_card", "silmu_naver", "0", "", "224243216770<script>", "12345678", "2242432167701234567" ].each do |raw|
      sub = subscribe(source_post: raw)
      assert_nil sub.source, "#{raw.inspect} 가 source 로 저장됐다"
    end
  end

  test "T3 기존 행(source NULL)은 그대로 유효하고, 재구독이 과거 source 를 채우지 않는다" do
    old = LawChangeSubscription.create!(email: "old-#{SecureRandom.hex(3)}@example.com", topic_slug: "overtime-allowance",
                                        topic_name: "초과근무수당", active: false)
    assert_nil old.source
    assert old.valid?

    subscribe(email: old.email, source_post: POST_ID)
    old.reload
    assert old.active, "재구독이 active 를 되살려야 한다(기존 동작)"
    assert_nil old.source, "과거 행에 새 글 번호를 backfill 했다"
  end

  test "first-touch — 이미 source 가 있는 구독은 다른 글 번호로 덮이지 않는다" do
    sub = subscribe(source_post: POST_ID)
    subscribe(email: sub.email, source_post: "224251599332")
    assert_equal POST_ID, sub.reload.source
  end

  test "구독 생성은 광고성 수신동의를 켜지 않는다 (로그인 사용자)" do
    user = User.create!(email: "u-#{SecureRandom.hex(3)}@example.com", password: "Passw0rd!secure", newsletter_agreed: false)
    sign_in user
    post law_change_subscriptions_path, params: { topic_slug: "overtime-allowance", topic_name: "초과근무수당", source_post: POST_ID }
    sub = LawChangeSubscription.find_by!(email: user.email, topic_slug: "overtime-allowance")
    assert_equal POST_ID, sub.source
    assert_equal false, user.reload.newsletter_agreed
    assert_not LawChangeSubscription.column_names.any? { |c| c =~ /consent|agree|marketing/ }
  end

  test "model — 형식 밖 source 는 저장 거부(방어선), nil 은 허용" do
    assert LawChangeSubscription.new(email: "a@example.com", topic_slug: "t", source: nil).valid?
    assert_not LawChangeSubscription.new(email: "a@example.com", topic_slug: "t", source: "cta_card").valid?
  end
end
