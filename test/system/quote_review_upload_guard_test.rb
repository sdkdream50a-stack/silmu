# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 — 견적 검토는 파일을 고르면 바로 서버(외부 AI)로 보낸다. 서버가 받지 않는 형식은
# 보내기 전에 브라우저에서 멈춰야 한다(드래그 앤 드롭은 accept 를 거치지 않는다).
class QuoteReviewUploadGuardTest < ApplicationSystemTestCase
  def analyze_calls
    page.evaluate_script("window.__analyzeCalls || 0")
  end

  setup do
    visit "/tools/quote-review"
    # 서버 호출 횟수를 센다 — fetch 를 감싸기만 하고 막지는 않는다.
    page.execute_script(<<~JS)
      window.__analyzeCalls = 0;
      const orig = window.fetch;
      window.fetch = function(url, opts) { if (String(url).includes('/quote-reviews/analyze')) window.__analyzeCalls++; return orig.apply(this, arguments); };
    JS
  end

  test "GIF 는 서버로 보내지 않고 JPG·PNG 안내를 띄운다" do
    page.execute_script(<<~JS, Rails.root.join("test/fixtures/files/tiny.gif").read.bytes)
      const bytes = new Uint8Array(arguments[0]);
      handleFile(new File([bytes], 'q.gif', { type: 'image/gif' }));
    JS
    assert_selector "#toast.show", text: "JPG·PNG만"
    assert_equal 0, analyze_calls
  end

  test "20MB 를 넘는 PDF 는 서버로 보내지 않는다" do
    page.execute_script("handleFile(new File([new Uint8Array(20 * 1024 * 1024 + 1)], 'big.pdf', { type: 'application/pdf' }));")
    assert_selector "#toast.show", text: "20MB"
    assert_equal 0, analyze_calls
  end
end
