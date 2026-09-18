# frozen_string_literal: true

require "test_helper"

# PHASE C / TOP6 — 토픽 본문에서 «계산은 어디서 하나» 까지의 거리.
#
# 운영 실측 2026-09-18 `/topics/private-contract`: 보이는 첫 도구 링크가 8,303px 지점
# (문서 11,892px 의 70% · 모바일 9.8화면 아래)이었다. 읽다가 계산이 필요해지는 지점은
# 본문 «앞» 인데 CTA 는 끝에만 있었다.
#
# 픽셀 거리는 test 로 잴 수 없다(렌더 엔진이 없다). 여기서는 **구조**를 본다 —
# 도구 링크가 본문 앞쪽에도 한 번 나오는가. 실제 거리는 실브라우저로 따로 쟀다.
class TopicToolProximityTest < ActionDispatch::IntegrationTest
  # ⚠️ 렌더된 토픽 페이지로는 잴 수 없다. 픽스처 토픽에 `category` 가 없어
  #    topics/show 가 test 환경에서 라우팅 에러로 렌더되지 않는다(선존재 · show:166).
  #    픽스처를 더하면 다른 테스트의 skip 임계가 풀린다고 fixtures/topics.yml 이 경고한다.
  #    그래서 여기서는 **템플릿의 구조**를 보고, 실제 픽셀 거리는 실브라우저로 따로 쟀다
  #    (운영 실측: 수리 전 첫 도구 링크 8,303px / 문서 11,892px = 70%).
  test "앞쪽 바로 계산 CTA 가 본문 흐름도보다 먼저 온다" do
    src = Rails.root.join("app/views/topics/show.html.erb").read

    early = src.index("early_tool = @related_tools.first")
    flow  = src.index("<!-- 실무흐름도 -->")
    assert early, "앞쪽 CTA 블록이 없다"
    assert flow,  "실무흐름도 지점을 찾지 못했다"
    assert early < flow, "앞쪽 CTA 가 본문 흐름도보다 뒤에 있다"
  end

  test "앞쪽 CTA 는 관련 도구가 있을 때만 난다" do  # 음성 대조 — 빈 카드를 만들지 않는가
    src = Rails.root.join("app/views/topics/show.html.erb").read
    assert src.include?("<% elsif @related_tools.any? %>"),
           "관련 도구 유무와 무관하게 CTA 가 렌더된다 — 빈 카드가 생긴다"
  end

  test "본문 끝 다음 행동 카드는 그대로 남아 있다" do  # 비퇴화
    # 앞으로 올리는 것이 끝의 카드를 없애는 것을 뜻하지 않는다.
    # 끝까지 읽은 사람에게도 다음 행동이 필요하다.
    src = Rails.root.join("app/views/topics/show.html.erb").read
    assert src.include?('data-next-action-topic-slug-value="<%= @topic.slug %>"'),
           "본문 끝 next-action 카드가 사라졌다"
  end

  test "앞쪽 CTA 에 동작하지 않는 추적 속성을 붙이지 않는다" do
    # Stimulus `next-action` 컨트롤러 범위 밖이라 data-action 은 발화하지 않는다.
    # 죽은 속성은 다음 사람에게 «추적되고 있다» 고 거짓말한다.
    src = Rails.root.join("app/views/topics/show.html.erb").read
    early = src[/early_tool = @related_tools\.first.*?<% end %>/m].to_s
    assert early.present?, "앞쪽 CTA 블록을 찾지 못했다"
    assert_not early.include?("next-action#track"),
             "컨트롤러 범위 밖인데 추적 action 이 붙어 있다"
  end
end
