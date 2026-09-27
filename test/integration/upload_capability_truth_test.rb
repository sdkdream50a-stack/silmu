# frozen_string_literal: true

require "test_helper"

# 2026-09-28 전 도구 기능 감사 — 업로드 화면이 «서버가 실제로 받는 것» 보다 넓게 말하지 않는다.
# 정본은 컨트롤러 상수다(QuoteReviewsController / QuoteDocumentsController::ALLOWED_CONTENT_TYPES·MAX_FILE_SIZE).
# PDF 는 텍스트만 읽는다(DocumentAnalyzerService#analyze_pdf) — 스캔본은 화면에 «못 읽는다» 고 적어야 한다.
class UploadCapabilityTruthTest < ActionDispatch::IntegrationTest
  EXT_FOR = { "image/jpeg" => %w[.jpg .jpeg], "image/png" => %w[.png], "application/pdf" => %w[.pdf] }.freeze

  def accept_of(body, id)
    body[/id="#{id}"[^>]*accept="([^"]+)"/, 1] || body[/accept="([^"]+)"[^>]*id="#{id}"/, 1]
  end

  test "견적 검토 — 파일 선택 칸은 서버 허용 형식(+브라우저에서 읽는 Excel)만 고르게 한다" do
    get "/tools/quote-review"
    assert_response :success
    accept = accept_of(response.body, "file-input").to_s.split(",")
    assert_not_includes accept, "image/*", "이미지 전반을 고르게 하면 서버가 거부하는 GIF·WEBP·HEIC 도 선택된다"

    server = QuoteReviewsController::ALLOWED_CONTENT_TYPES.flat_map { |t| EXT_FOR.fetch(t) }
    assert_equal server.sort, (accept - %w[.xlsx .xls]).sort, "서버 허용 형식과 파일 선택 칸이 다르다"
  end

  test "견적 검토 — 드래그 앤 드롭 경로도 같은 형식·크기로 막는다" do
    get "/tools/quote-review"
    body = response.body
    assert_includes body, "const QR_IMAGE_TYPES = ['image/jpeg', 'image/png'];"
    limit = body[/const QR_MAX_BYTES = (\d+) \* 1024 \* 1024;/, 1].to_i.megabytes
    assert_equal QuoteReviewsController::MAX_FILE_SIZE, limit, "화면 크기 제한이 서버와 다르다"
  end

  test "견적 검토·견적서 자동 추출 — 스캔본 PDF 는 읽지 못한다고 업로드 전에 적는다" do
    %w[/tools/quote-review /tools/quote-auto].each do |path|
      get path
      assert_response :success
      assert_includes response.body, "스캔본 PDF는 글자를 읽지 못합니다", "#{path} 가 PDF 를 조건 없이 지원하는 것처럼 보인다"
      assert_includes response.body, "20MB", "#{path} 에 파일 크기 제한이 없다"
    end
  end

  test "음성 대조 — 서버가 받는 형식은 화면에서도 여전히 고를 수 있다" do
    get "/tools/quote-auto"
    accept = accept_of(response.body, "qd-file-input").to_s.split(",")
    QuoteDocumentsController::ALLOWED_CONTENT_TYPES.each do |t|
      assert (EXT_FOR.fetch(t) & accept).any?, "#{t} 를 서버는 받는데 파일 선택 칸이 막는다"
    end
  end
end
