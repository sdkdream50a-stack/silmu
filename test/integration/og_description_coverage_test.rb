# frozen_string_literal: true

require "test_helper"

# PHASE D — `og:description` 커버리지.
#
# 운영 실측 2026-09-18: 도구 14개 중 **4개**(contract-method·estimated-price·
# contract-guarantee·contract-documents)와 **/school-office** 에 og:description 이 없었다.
# 원인은 페이지별 누락이 아니라 **기본값에 없었던 것**이다 — 컨트롤러가 og 해시를
# 부분만 넘기면(`og: { title:, url: }`) description 이 통째로 빠진다.
# 카톡·SNS 공유 시 설명이 빈 칸으로 나가고, 연수 QR·슬라이드 링크가 그 경로다.
#
# 그래서 페이지를 하나씩 고치지 않고 **기본값 한 곳**을 고쳤다. 이 테스트는 그 구조를 지킨다.
class OgDescriptionCoverageTest < ActionDispatch::IntegrationTest
  PAGES = {
    "/tools/contract-method"     => "og 해시를 부분만 넘기던 대표 사례",
    "/tools/estimated-price"     => "같은 패턴",
    "/tools/contract-guarantee"  => "같은 패턴",
    "/tools/contract-documents"  => "같은 패턴",
    "/school-office"             => "연수 QR 착지점",
    "/tools/overtime-calculator" => "원래 있던 페이지(비퇴화)"
  }.freeze

  test "공유 대상 페이지에 og:description 이 있다" do
    PAGES.each do |path, why|
      get path
      assert_response :success, "#{path} 가 열리지 않는다"
      assert_match(/property="og:description" content="[^"]+"/, response.body,
                   "#{path} 에 og:description 이 없다 (#{why}) — 공유 시 설명이 빈 칸으로 나간다")
    end
  end

  test "og:description 이 그 페이지의 description 과 같다" do
    # 기본값을 심볼 참조로 주면 «렌더 시점의 페이지 description» 이 들어간다.
    # 전역 기본 문구가 모든 페이지에 복사되면 그건 커버리지가 아니라 잡음이다.
    get "/tools/contract-method"
    desc = response.body[/<meta name="description" content="([^"]+)"/, 1]
    og   = response.body[/property="og:description" content="([^"]+)"/, 1]
    assert desc.present? && og.present?, "메타를 찾지 못했다"
    assert_equal desc, og, "og:description 이 페이지 description 과 다르다"
  end

  test "페이지가 자기 og:description 을 명시하면 그 값이 이긴다" do  # 음성 대조
    get "/tools/quote-review"
    assert_response :success
    og = response.body.scan(/property="og:description" content="([^"]+)"/).flatten
    assert_equal 1, og.size, "og:description 이 #{og.size}개다 — 기본값과 중복 출력됐다"
  end
end
