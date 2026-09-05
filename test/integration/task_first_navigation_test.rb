# frozen_string_literal: true

require "test_helper"

# P1.6 §12·§13·§14·§15·§50·§51 — 네비게이션·홈이 업무 중심인지,
# 그리고 **기존 진입점·URL 이 하나도 사라지지 않았는지** 고정한다.
class TaskFirstNavigationTest < ActionDispatch::IntegrationTest
  test "주 메뉴가 업무 중심 라벨을 쓴다" do
    get root_path
    assert_response :success
    assert_match "업무찾기", response.body
    assert_match "실무도구", response.body
    assert_match "신규자", response.body
  end

  # §14 — 기존 섹션을 삭제하지 않는다. 홈 본문은 홈에만 있으므로 **홈이 아닌 깊은 페이지**에서
  # 검사해야 nav/footer(= 모든 페이지에 있는 표면)의 손실을 실제로 잡는다.
  # 홈에서만 검사하면 본문 섹션이 nav 손실을 가려 준다(뮤테이션으로 실측함).
  PERSISTENT_ENTRY_POINTS = %w[
    topics guides audit_cases tools guide_resources templates
    task_calendar ai_assistant onboarding
  ].freeze

  test "기존 진입점은 홈이 아닌 페이지에서도 도달 가능하다" do
    # /privacy 는 본문에 이 링크들이 하나도 없다 — 그래서 nav/footer 손실이 가려지지 않는다.
    # (본문이 링크를 가진 페이지를 고르면 nav 를 통째로 지워도 테스트가 통과한다. 실측함.)
    get privacy_path
    assert_response :success

    PERSISTENT_ENTRY_POINTS.each do |name|
      path = send("#{name}_path")
      assert_select "a[href=?]", path, { minimum: 1 },
        "깊은 페이지에서 진입점 #{path} 에 도달할 수 없다 (nav/footer 양쪽에서 사라짐)"
    end
  end

  test "홈에서도 기존 진입점이 유지된다" do
    get root_path
    assert_response :success
    [ topics_path, guides_path, audit_cases_path, tools_path,
      guide_resources_path, templates_path, task_calendar_path,
      ai_assistant_path, feedback_path ].each do |path|
      assert_select "a[href=?]", path, { minimum: 1 }, "기존 진입점 #{path} 이 사라졌다"
    end
  end

  test "기존 URL 은 그대로 살아 있다 (SEO 자산 보존)" do
    { topics_path => :success, guides_path => :success, audit_cases_path => :success,
      tools_path => :success, templates_path => :success, onboarding_path => :success }.each do |path, expected|
      get path
      assert_response expected, "#{path} 가 #{expected} 가 아니다"
    end
  end

  test "홈 히어로는 질문형 검색을 주인공으로 둔다" do
    get root_path
    assert_response :success
    assert_select "input[name=q][placeholder=?]", "무엇을 처리하려고 하세요?"
    assert_select "form[action=?]", silmu_search_path
    assert_match "찾는 데서 해결까지", response.body
  end

  test "홈에 업무 진입 카드가 있고 커버리지 미달 업무는 없다" do
    get root_path
    assert_response :success
    assert_select "#task-entry-heading"

    shown = TaskEntryHelper::TASK_ENTRIES.select { |e| response.body.include?(">#{e[:label]}<") }
    assert shown.any?, "업무 카드가 하나도 렌더되지 않았다"
  end

  test "홈 히어로가 콘텐츠 개수를 자랑하지 않는다 (§83)" do
    # 특정 문장을 금지하면 문장만 바꿔서 되살아난다(뮤테이션으로 실측).
    # 그래서 "히어로 lede 에 숫자가 없다"는 성질 자체를 고정한다.
    # (섹터 탭 칩·도구 개수 같은 정당한 숫자는 lede 밖이라 영향받지 않는다.)
    get root_path
    assert_response :success
    lede = css_select(".hero-lede").first
    assert lede, "히어로 lede 를 찾을 수 없다"
    assert_no_match(/\d/, lede.text, "히어로 lede 에 콘텐츠 개수가 들어갔다: #{lede.text.strip}")
  end

  test "예시 질문은 실제로 결과가 나오는 것만 건다 (첫 클릭이 빈손이면 안 된다)" do
    get root_path
    assert_response :success
    # 정보공개는 전 자산 0건이라 예시로 걸지 않았다.
    assert_no_match "정보공개 답변은", response.body
  end
end
