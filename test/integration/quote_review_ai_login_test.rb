# frozen_string_literal: true

require "test_helper"

# 견적 검토 AI 분석(외부 AI 전송)은 다른 AI 도구와 같이 로그인 사용자만 쓴다(a0ff4d2 정책).
# 2026-09-28 감사 전에는 익명 요청도 파일을 외부 AI 로 보냈다.
class QuoteReviewAiLoginTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def png
    Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n\x1a\n".b + "x" * 32), "image/png", true, original_filename: "q.png")
  end

  # minitest/mock 이 없는 환경이라 .new 를 잠시 바꿔 끼운다.
  def with_analyzer(fake)
    orig = DocumentAnalyzerService.method(:new)
    DocumentAnalyzerService.define_singleton_method(:new) { |*| fake.respond_to?(:call) ? fake.call : fake }
    yield
  ensure
    DocumentAnalyzerService.define_singleton_method(:new, orig)
  end

  def post_analyze
    post "/quote-reviews/analyze", params: { file: png }, headers: { "Accept" => "*/*", "Origin" => "http://www.example.com", "Referer" => "http://www.example.com/tools/quote-review" }
  end

  test "익명 요청은 외부 AI 를 부르지 않고 401 login_required 를 돌려준다" do
    called = false
    with_analyzer(-> { called = true; raise "must not be called" }) do
      post_analyze
    end
    assert_response :unauthorized
    assert_equal true, response.parsed_body["login_required"]
    assert_not called, "로그인 없이 문서 분석 서비스(외부 AI)가 호출됐다"
  end

  test "양성 대조 — 로그인 사용자는 분석 서비스까지 간다" do
    sign_in User.create!(email: "qr-#{SecureRandom.hex(4)}@example.com", password: "password123456")
    fake = Object.new
    def fake.analyze(file:, document_type:) = { success: true, fields: { "contract_type" => "물품" } }
    with_analyzer(fake) { post_analyze }
    assert_response :success
    assert_equal true, response.parsed_body["success"]
  end

  test "비로그인 화면은 업로드 전에 AI 분석이 로그인 필요임을 알린다" do
    get "/tools/quote-review"
    assert_includes response.body, "AI 자동 분석은"
    sign_in User.create!(email: "qr-#{SecureRandom.hex(4)}@example.com", password: "password123456")
    get "/tools/quote-review"
    assert_not_includes response.body, "AI 자동 분석은", "로그인 사용자에게도 로그인 안내가 나온다"
  end
end
