# frozen_string_literal: true

require "test_helper"

# P0-3 (2026-09-18) — 이 repo 의 첫 system test 기반.
#
# 왜 필요했나: 서식 다운로드 버튼이 «있는데 안 눌린다» 였다. 통합 테스트는 응답 HTML 만 보므로
#   «클릭해도 아무 일 없음» 을 재현하지 못한다. 실제 브라우저로 눌러 봐야 한다.
#
# chromedriver 는 Selenium Manager 가 자동으로 받는다(selenium-webdriver 4.x).
# CI 는 `bin/rails test:system` 을 별도 job 으로 돈다 — 기본 `test` 태스크에는 포함되지 않는다.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]
end
