# frozen_string_literal: true

require "test_helper"

# 2026-09-28 전 도구 기능 감사 finding C·D — 검증실 업로드 칸이 서버·파서가 실제로 받는 것만 고르게 하고,
# 크기 제한을 업로드 전에 보여 준다. 숫자의 정본은 상수다(TextExtractor::MAX_BYTES · ReviewLabController::MAX_TOTAL_BYTES).
class ReviewLabCapabilityTruthTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PAGES = %w[/review-lab/quote /review-lab/budget /review-lab/package].freeze

  # 화면마다 새로 로그인한다 — 한 세션으로 여러 화면을 돌면 두 번째부터 로그인 안내가 나왔다(테스트 세션 문제).
  def signed_get(path)
    sign_in User.create!(email: "cap-#{SecureRandom.hex(4)}@example.com", password: "password123456")
    get path
  end

  test "세 검토 모두 업로드 전에 파일당·합계 크기 제한을 상수 값으로 보여 준다" do
    per_file = ReviewLab::TextExtractor::MAX_BYTES / 1.megabyte
    total = ReviewLabController::MAX_TOTAL_BYTES / 1.megabyte
    PAGES.each do |path|
      signed_get path
      assert_response :success
      assert_includes response.body, "파일당 최대 #{per_file}MB · 합계 #{total}MB", "#{path} 에 크기 제한이 없다"
    end
  end

  test "바이너리 HWP 는 파서가 거부하므로 파일 선택 칸에서도 고를 수 없다(HWPX 는 그대로)" do
    PAGES.each do |path|
      signed_get path
      accepts = response.body.scan(/type="file"[^>]*accept="([^"]+)"/).flatten + response.body.scan(/accept="([^"]+)"[^>]*type="file"/).flatten
      assert accepts.any?, "#{path} 에서 파일 칸을 못 찾았다 — 이 검사는 무효"
      accepts.each do |a|
        list = a.split(",")
        assert_not_includes list, ".hwp", "#{path} 가 읽지 못하는 HWP 를 고르게 한다"
        assert_includes list, ".hwpx", "#{path} 가 읽을 수 있는 HWPX 까지 막았다"
      end
    end
  end

  test "음성 대조 — 파서는 여전히 HWP 를 명시 안내와 함께 거부한다" do
    assert_match(/HWP\(한글 97~2022 기본 형식\)/, ReviewLab::TextExtractor::MESSAGES[:ole]) if defined?(ReviewLab::TextExtractor::MESSAGES)
    assert_includes File.read(Rails.root.join("app/services/review_lab/text_extractor.rb")), "HWP(한글 97~2022 기본 형식)"
  end
end
