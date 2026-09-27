# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-27 — 사용자가 «파일은 어디로 어떻게 올리나» 를 물었다.
# 원인: OS 다크모드용 강제 라이트 CSS 가 모든 input 의 배경을 `inherit !important` 로 덮어
#   «검토하기» 제출 버튼이 글자처럼 보였고, 파일 칸에는 버튼 모양이 없었다.
# 통합 테스트는 HTML 만 보므로 계산된 스타일을 실제 브라우저에서 잰다.
class ReviewLabUploadVisibilityTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  NAVY = "rgb(30, 90, 168)" # --color-editorial-navy #1E5AA8

  teardown do
    Warden.test_reset!
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  def color_scheme(scheme)
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia",
                                    features: [ { name: "prefers-color-scheme", value: scheme } ])
  end

  def styles
    page.evaluate_script(<<~JS)
      (() => {
        const submit = document.querySelector('form input[type=submit]');
        const file = document.querySelector('form input[type=file]');
        return {
          dark: matchMedia('(prefers-color-scheme: dark)').matches,
          submit: getComputedStyle(submit).backgroundColor,
          submitText: getComputedStyle(submit).color,
          fileButton: getComputedStyle(file, '::file-selector-button').backgroundColor
        };
      })()
    JS
  end

  %w[light dark].each do |scheme|
    test "#{scheme} — 사업계획 검토의 검토하기·파일 선택 버튼이 남색으로 보인다" do
      login_as users(:one), scope: :user
      visit review_lab_budget_path
      color_scheme(scheme)
      assert_text "올리는 방법"

      s = styles
      assert_equal(scheme == "dark", s["dark"], "색 모드 에뮬레이션이 적용되지 않았다 — 이 측정은 무효")
      assert_equal NAVY, s["submit"], "검토하기 버튼 배경이 남색이 아니다(#{scheme})"
      assert_equal "rgb(255, 255, 255)", s["submitText"], "검토하기 버튼 글자가 흰색이 아니다(#{scheme})"
      assert_equal NAVY, s["fileButton"], "파일 선택 버튼 배경이 남색이 아니다(#{scheme})"

      page.save_screenshot(Rails.root.join("tmp/screenshots/review_lab_upload_#{scheme}.png").to_s) if ENV["SAVE_SHOTS"]
    end
  end
end
