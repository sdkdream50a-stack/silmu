# frozen_string_literal: true

require "application_system_test_case"

# 2026-09-18 실브라우저 리허설에서 나온 결함.
#
# 토픽 탭 바(`nav#topic-tabs`)는 `overflow-x-auto` 다. CSS 상 overflow-x 가 auto 면
# overflow-y 도 auto 로 계산되므로, 그 안에 `absolute` 로 띄운 «더보기» 드롭다운이
# **세로로 잘린다**. 운영(93f76d31)에서 데스크톱 1085px·모바일 390px 둘 다
# 4개 항목(예규/지침·질의·회신 예시·질의답변·실무주의)이 elementFromPoint 로 잡히지 않았다
# — 즉 보이지도, 눌리지도 않았다. 그 탭 안에 「법정 위원회가 아니다」 같은 판정 문구가 있다.
#
# HTML 에 있다 ≠ 사용자가 누를 수 있다. 그래서 이 테스트는 문자열이 아니라 **좌표 히트테스트**로 잰다.
class TopicMoreTabsTest < ApplicationSystemTestCase
  UNREACHABLE_JS = <<~JS
    (() => [...document.querySelectorAll('.more-tab-item')].filter(it => {
      const r = it.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return true;
      const hit = document.elementFromPoint(Math.round(r.left + r.width / 2), Math.round(r.top + r.height / 2));
      return !(hit && (hit === it || it.contains(hit)));
    }).map(it => it.innerText.trim()))()
  JS

  # 픽스처 토픽에는 category 가 없어 show 뷰의 breadcrumb 이 라우팅에서 죽는다.
  # 이 테스트가 재는 축(탭 드롭다운)과 무관하므로 여기서 최소 조건만 갖춘 토픽을 만든다.
  setup do
    @topic = Topic.create!(name: "더보기 탭 테스트 토픽", slug: "system-more-tabs-topic",
                           category: "contract", summary: "탭 드롭다운 회귀 테스트용",
                           published: true)
  end

  def open_more_menu(slug = @topic.slug)
    visit topic_path(slug)
    assert_selector "#more-tabs-btn"
    find("#more-tabs-btn").click
  end

  test "더보기 항목이 전부 화면에서 눌릴 수 있다 (데스크톱)" do
    open_more_menu

    # 양성대조: 항목이 실제로 4개 렌더된다 — 0개면 «잘린 것»이 아니라 «안 만든 것»이고 이 판정은 무의미하다.
    assert_equal 4, all(".more-tab-item", visible: :all).size

    assert_empty page.evaluate_script(UNREACHABLE_JS),
                 "더보기 메뉴 항목이 잘려 클릭되지 않는다(overflow 클리핑)"
  end

  test "더보기 항목이 전부 화면에서 눌릴 수 있다 (모바일 390px)" do
    Capybara.current_session.current_window.resize_to(390, 844)
    open_more_menu
    assert_empty page.evaluate_script(UNREACHABLE_JS),
                 "모바일 폭에서 더보기 메뉴 항목이 잘려 클릭되지 않는다"
  ensure
    Capybara.current_session.current_window.resize_to(1400, 1000)
  end

  test "더보기에서 예규/지침을 눌러 그 패널을 실제로 연다" do
    open_more_menu
    find(".more-tab-item", text: "예규/지침").click

    assert_selector "#panel-regulation", visible: true
    assert_no_selector "#more-tabs-dropdown:not(.hidden)", wait: 2
  end

  # 음성대조 — 이 판정기가 «잘림»을 실제로 잡는지 증명한다.
  # 수리 전 상태(= absolute 로 되돌리기)를 만들면 같은 스크립트가 4개 전부를 «못 누른다»고 말해야 한다.
  # 이게 없으면 위 assert_empty 는 «측정이 안 된 것»과 구별되지 않는다.
  test "음성대조: absolute 로 되돌리면 항목이 잘려 잡힌다" do
    open_more_menu
    page.execute_script(<<~JS)
      const dd = document.getElementById('more-tabs-dropdown');
      dd.style.position = 'absolute'; dd.style.top = ''; dd.style.left = '';
    JS
    assert_equal 4, page.evaluate_script(UNREACHABLE_JS).size,
                 "수리 전 상태를 재현했는데도 «잘림»이 잡히지 않는다 — 판정기가 죽어 있다"
  end

  test "메뉴를 연 뒤 스크롤해도 버튼 아래에 붙어 있다" do
    open_more_menu
    page.execute_script("window.scrollBy(0, 600)")
    sleep 0.3

    gap = page.evaluate_script(<<~JS)
      (() => {
        const b = document.getElementById('more-tabs-btn').getBoundingClientRect();
        const d = document.getElementById('more-tabs-dropdown').getBoundingClientRect();
        return Math.round(Math.abs(d.top - b.bottom));
      })()
    JS
    assert_operator gap, :<=, 12, "스크롤 후 드롭다운이 버튼에서 떨어졌다(gap=#{gap}px)"
  end
end
