# frozen_string_literal: true

require "test_helper"

# 2026-09-18 — AdSense 무효트래픽 스크립트(sodar2.js)가 CSP 로 차단되고 있었다.
# 응답 헤더의 **script-src 지시자 안**만 본다 — 파일이나 헤더 전체를 grep 하면
# connect-src·frame-src 의 같은 호스트를 «허용돼 있다»고 잘못 읽는다(선행 세션이 실제로 낸 오류 유형).
class CspAdsenseHostsTest < ActionDispatch::IntegrationTest
  SODAR_HOSTS = %w[ep1.adtrafficquality.google ep2.adtrafficquality.google].freeze

  def script_src_directive
    get root_path
    header = response.headers["Content-Security-Policy"].to_s
    assert header.present?, "CSP 헤더 자체가 없다 — 이 검사는 대상이 없다"
    header.split(";").map(&:strip).find { |d| d.start_with?("script-src ") }.to_s
  end

  test "AdSense 로더를 쓰는 동안 sodar 호스트가 script-src 에 있다" do
    layout = Rails.root.join("app/views/layouts/application.html.erb").read
    adsense_present = layout.include?("adsbygoogle.js")

    directive = script_src_directive
    # 양성대조: 이미 허용된 AdSense 호스트가 이 지시자에서 실제로 보여야 한다.
    assert_includes directive, "pagead2.googlesyndication.com",
                    "script-src 를 잘못 잘라 읽고 있다 — 기존 허용 호스트도 안 보인다"

    if adsense_present
      SODAR_HOSTS.each do |host|
        assert_includes directive, host,
                        "#{host} 가 script-src 에 없다 — sodar2.js 가 차단돼 광고 품질 신호가 끊긴다"
      end
    else
      skip "AdSense 로더가 레이아웃에 없다 — 이 불변식의 대상이 없다"
    end
  end

  test "connect-src·frame-src 에만 있는 상태를 통과로 읽지 않는다" do
    directive = script_src_directive
    refute directive.start_with?("connect-src"), "지시자 선택이 틀렸다"
    assert_equal 1, directive.scan(/\Ascript-src\s/).size
  end
end
