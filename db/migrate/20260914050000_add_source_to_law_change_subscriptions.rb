# 리드 글 귀속 키 — 2026-09-14 (dream40a → silmu.kr 도구 → 구독 퍼널)
#
# source = 구독 직전 착지의 utm_content(네이버 글 logNo). 규약은 새로 만들지 않았다:
#   utm_source=naver_blog · utm_medium=referral · utm_campaign=silmu_naver · utm_content=<logNo>
# 기존 행은 NULL 그대로 둔다 — 과거 출처를 추측해 채우지 않는다(NULL = UNMEASURED, 0/직접유입 아님).
# 광고성 수신동의(users.newsletter_agreed)와 무관한 컬럼이다.
class AddSourceToLawChangeSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :law_change_subscriptions, :source, :string
  end
end
