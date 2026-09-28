# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-28 — quote-review 는 파일을 고르거나 드롭한 순간 곧장 외부 AI(Anthropic)로 보냈다.
# 다른 AI 업로드 도구(review-lab 체크박스, quote-auto «AI 분석 시작» 버튼)처럼
# 명시적인 행동(«AI로 읽기» 버튼 클릭)이 있어야 전송하도록 바꾼다.
class QuoteReviewAiOptinTest < ApplicationSystemTestCase
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

  test "이미지를 고르면 미리보기와 «AI로 읽기» 버튼만 뜨고 분석 요청은 나가지 않는다" do
    page.execute_script(<<~JS)
      handleFile(new File([new Uint8Array([1, 2, 3, 4])], 'q.png', { type: 'image/png' }));
    JS
    assert_selector "#preview-container.show"
    assert_selector "#ai-optin-box", visible: true
    assert_equal 0, analyze_calls
  end

  test "«AI로 읽기» 버튼을 눌러야 분석 요청이 나간다" do
    page.execute_script(<<~JS)
      handleFile(new File([new Uint8Array([1, 2, 3, 4])], 'q.png', { type: 'image/png' }));
    JS
    assert_equal 0, analyze_calls

    find("#btn-ai-analyze").click

    assert_equal 1, analyze_calls
  end

  test "PDF 를 고르면 분석 요청 없이 «AI로 읽기» 버튼이 뜬다" do
    page.execute_script(<<~JS)
      handleFile(new File([new Uint8Array([1, 2, 3, 4])], 'q.pdf', { type: 'application/pdf' }));
    JS
    assert_selector "#ai-optin-box", visible: true
    assert_equal 0, analyze_calls
  end

  test "파일을 바꾸면 이전 옵트인 상태를 버리고 새 파일에 대해서만 다시 뜬다" do
    page.execute_script(<<~JS)
      handleFile(new File([new Uint8Array([1, 2, 3, 4])], 'first.png', { type: 'image/png' }));
    JS
    assert_selector "#ai-optin-box", visible: true

    page.execute_script(<<~JS)
      handleFile(new File([new Uint8Array([1, 2, 3, 4])], 'second.png', { type: 'image/png' }));
    JS
    assert_selector "#ai-optin-box", visible: true
    assert_equal 0, analyze_calls

    find("#btn-ai-analyze").click
    assert_equal 1, analyze_calls
  end
end
