# frozen_string_literal: true

require "test_helper"

# G-64 (2026-09-18) — **평시 save 경로**의 교차모델 캐시 무효화.
#
# G-57 은 migration 경로(`update_columns`)를 닫았다. 이 파일은 그 옆의 구멍을 닫는다:
# 관리자가 화면에서 Guide·AuditCase 를 고치는 평범한 save 다.
#
#   `related_content_v2/<topic_slug>/guides` 는 **Topic slug** 로 갈라지는데 내용물은
#   Guide 객체다. Guide 의 콜백은 전부 «가이드 자신의 slug» 로 된 키만 지우므로 그 캐시에
#   닿지 않았다 → 토픽 화면이 TTL 동안 옛 제목·옛 목록을 서빙한다.
#
# ⚠️ test 환경 cache_store 는 `:null_store` 라 아무것도 저장되지 않는다.
#    그 상태로 재면 «지워졌다» 와 «애초에 없었다» 가 구별되지 않는다(2026-09-18 자기 결함 #4).
#    그래서 MemoryStore 로 바꿔 끼우고, **음성 대조 키**로 store 가 살아 있음을 먼저 확인한다.
class CrossModelCacheInvalidationTest < ActiveSupport::TestCase
  setup do
    @original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @original }

  test "store 가 실제로 저장한다 — 이 검사가 실패하면 아래 «지워졌다» 는 무의미하다" do
    Rails.cache.write("probe/alive", "yes")
    assert_equal "yes", Rails.cache.read("probe/alive"),
                 "cache store 가 null_store 다 — 아래 무효화 검사는 측정이 아니다"
  end

  test "가이드를 저장하면 토픽의 related guides 캐시가 지워진다" do
    topic = Topic.published.first
    assert topic, "published 토픽 픽스처가 필요하다"

    key = "related_content_v2/#{topic.slug}/guides"
    Rails.cache.write(key, "옛 가이드 목록")
    # 음성 대조 — 무관한 kind 는 살아 있어야 한다(무차별 삭제가 아님을 보인다)
    Rails.cache.write("related_content_v2/#{topic.slug}/topics", "관련 토픽")

    guide = Guide.first
    assert guide, "가이드 픽스처가 필요하다"
    guide.update!(summary: "#{guide.summary} (갱신)")

    assert_nil Rails.cache.read(key), "가이드를 고쳤는데 토픽의 관련 가이드 캐시가 그대로다"
    assert_equal "관련 토픽", Rails.cache.read("related_content_v2/#{topic.slug}/topics"),
                 "무관한 kind 까지 지웠다"
  end

  test "감사사례를 저장하면 토픽의 related audit_cases 캐시가 지워진다" do
    topic = Topic.published.first
    key = "related_content_v2/#{topic.slug}/audit_cases"
    Rails.cache.write(key, "옛 사례 목록")
    Rails.cache.write("related_content_v2/#{topic.slug}/guides", "관련 가이드")

    ac = AuditCase.first
    assert ac, "감사사례 픽스처가 필요하다"
    ac.update!(issue: "#{ac.issue} (갱신)")

    assert_nil Rails.cache.read(key), "감사사례를 고쳤는데 토픽의 관련 사례 캐시가 그대로다"
    assert_equal "관련 가이드", Rails.cache.read("related_content_v2/#{topic.slug}/guides"),
                 "무관한 kind 까지 지웠다"
  end

  test "topic_slug 가 없는 레코드를 고쳐도 지운다 — fallback 으로 다른 토픽 목록에 들어가 있다" do
    topic = Topic.published.first
    key = "related_content_v2/#{topic.slug}/guides"
    Rails.cache.write(key, "옛 목록")

    guide = Guide.first
    guide.update!(topic_slug: nil, summary: "topic_slug 없는 가이드")

    assert_nil Rails.cache.read(key),
               "topic_slug 가 없다고 건너뛰면 fallback 으로 들어간 목록이 낡은 채 남는다"
  end

  test "알 수 없는 kind 는 조용히 통과하지 않고 거부한다" do
    assert_raises(ArgumentError) { ContentCache.invalidate_related!(:nope) }
  end
end
