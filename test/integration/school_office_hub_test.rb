# frozen_string_literal: true

require "test_helper"

# P1-1 — 학교 행정실 상설 허브(`/school-office`).
#
# 이 페이지의 유일한 약속은 «여기 적힌 것은 실제로 있다» 다. 죽은 링크가 하나라도 있으면
# 연수 QR 착지점이 거짓이 된다.
#
# ⚠️ 검사를 두 우주로 나눈다. 첫 판본은 전 경로를 test 에서 GET 했는데 17건이 «죽은 링크» 로
#    나왔다 — 실제로는 **test DB 픽스처에 그 레코드가 없을 뿐**이고 운영에서는 32건 전부 200 이다.
#    그 상태로 두면 「내 검사가 보는 우주」를 사실로 착각하게 된다.
#      · 코드 불변식(경로가 라우팅되는가·중복·표시 규칙) → 이 파일
#      · 데이터 불변식(그 slug 의 레코드가 실제로 있는가) → 운영 스모크
#        (tools/smoke_lecture_p0_0918.sh 의 P1-1 절이 운영에서 전 경로를 GET 한다)
class SchoolOfficeHubTest < ActionDispatch::IntegrationTest
  test "허브가 열린다" do
    get school_office_url
    assert_response :success
    assert response.body.include?("학교 행정실 바로가기")
  end

  test "허브가 링크한 모든 경로가 라우팅된다" do
    paths = SchoolOfficeController.all_paths
    assert_operator paths.size, :>=, 20, "허브 항목이 비정상적으로 적다"
    assert_equal paths.uniq, paths, "같은 경로가 중복 등록됐다"

    unroutable = paths.reject do |path|
      Rails.application.routes.recognize_path(path.split("?").first, method: :get)
      true
    rescue ActionController::RoutingError
      false
    end

    assert_empty unroutable, "허브에 라우팅되지 않는 경로가 있다: #{unroutable.join(', ')}"
  end

  test "라우팅 검사가 실제로 오탐을 잡는다" do  # 양성 대조 — 위 검사가 살아 있는가
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/존재할수없는경로ZZZQQQ9999", method: :get)
    end
  end

  test "정적 경로는 test 에서도 실제로 열린다" do
    # 레코드가 필요 없는 경로만 — 픽스처 유무와 무관하게 성립한다.
    %w[/tools/contract-method /tools/split-contract-checker /tools/annual-leave-calculator
       /tools/overtime-calculator /tools/allowance-calculator /tools/budget-execution-rate
       /tools/budget-category-finder /tools/budget-transfer-checker /tools/task-calendar
       /start /audit-cases].each do |path|
      get path
      assert_response :success, "#{path} 가 열리지 않는다"
    end
  end

  # ── P0 (2026-09-20 · STANDARD_SEPARATION) ────────────────────────────────
  # 이전 판본은 지자체 기준 도구에 주황색 note 만 붙이고 핵심 카드 자리에 뒀다.
  # 이 화면의 이름이 «학교 행정실 바로가기» 라서, 자리 자체가 «학교에서 쓰는 것» 이라는 약속이다.
  # 그래서 아래 검사들은 **문구가 아니라 자리**를 잰다.

  # 지자체 기준으로 판정된 자산(판정 근거 = config/tool_trust.yml jurisdiction · guide seed laws).
  LOCALGOV_PATHS = %w[/tools/budget-category-finder /tools/budget-transfer-checker
                      /guides/budget-execution-complete-3].freeze

  test "지자체 기준 자산이 핵심 카드에 0건" do
    primary = SchoolOfficeController.primary_items.map { |i| i[:path] }

    leaked = LOCALGOV_PATHS & primary
    assert_empty leaked, "지자체 기준 자산이 아직 핵심 카드에 있다: #{leaked.join(', ')}"
  end

  test "핵심 카드 0건 검사가 실제로 오탐을 잡는다" do  # 양성 대조
    # ⚠️ 첫 판본은 «찾을 값을 직접 심은 배열»에 교집합을 걸어서, 컨트롤러가 무엇을 하든
    #    항상 통과하는 항진식이었다(2026-09-20 독립 리뷰 F2). 대조가 되려면 **같은 검사식**을
    #    진짜 입력과 결함 입력에 각각 먹여, 한쪽은 통과하고 한쪽은 걸려야 한다.
    detect = lambda do |items|
      LOCALGOV_PATHS & items.map { |i| i[:path] }
    end

    assert_empty detect.call(SchoolOfficeController.primary_items),
                 "실제 핵심 카드에서 지자체 기준이 검출됐다"
    # 결함 주입: 접어 둔 참고자료를 핵심 카드로 올린 상태
    planted = SchoolOfficeController.primary_items + SchoolOfficeController.reference_items
    assert_not_empty detect.call(planted),
                     "참고자료를 핵심으로 올렸는데도 검사가 통과한다 — 검사식이 죽어 있다"
  end

  test "참고자료는 접힌 영역 안에만 있다" do
    get school_office_url
    body = response.body

    refs = SchoolOfficeController.reference_items
    assert refs.any?, "참고자료로 내린 자산이 하나도 없다 — 판정표(01_CARD_STANDARD_CENSUS)와 어긋난다"

    assert body.include?("<details"), "접힌 참고자료 영역이 없다"
    assert body.include?(SchoolOfficeController::REFERENCE_HEADING), "참고자료 영역 제목이 없다"
    assert body.include?(SchoolOfficeController::REFERENCE_LEAD), "참고자료가 왜 다른지 적혀 있지 않다"

    # ⚠️ 첫 판본은 `body.split("<details").first` 로 **첫 번째 접힘 앞**만 봤고 slot 접두어를
    #    `budget:` 으로 박아 뒀다. 그러면 나중에 급여·물품 축에 참고자료가 생겨 핵심 카드로
    #    새어도 잡히지 않는다(2026-09-20 독립 리뷰 F1). 축마다 자기 블록 안에서 본다.
    SchoolOfficeController::SECTIONS.each do |section|
      section_refs = section[:items].select { |i| i[:tier] == :reference }
      next if section_refs.empty?

      section_html = body.split(%(<section id="#{section[:id]}"))[1].to_s.split("</section>").first.to_s
      assert section_html.present?, "#{section[:id]} 축 블록을 찾지 못했다 — 검사가 빈 문자열을 통과시킨다"
      before_fold = section_html.split("<details").first.to_s

      section_refs.each do |item|
        slot = %(next-action-slot-param="#{section[:id]}:#{item[:path]}")
        assert section_html.include?(slot), "#{section[:id]}: #{item[:path]} 가 아예 렌더되지 않았다"
        assert_not before_fold.include?(slot),
                   "#{section[:id]}: #{item[:path]} 가 접히기 전 영역에 있다"
      end
    end
  end

  test "참고자료 영역이 기본으로 접혀 있다" do  # open 속성이 붙으면 «접었다» 가 거짓이 된다
    get school_office_url
    assert_no_match(/<details[^>]*\sopen/, response.body, "참고자료가 펼쳐진 채로 렌더된다")
  end

  test "조건부 자산에는 라벨과 «무엇이 다른지» 가 함께 붙는다" do
    get school_office_url
    body = response.body

    conditional = SchoolOfficeController::SECTIONS.flat_map { |s| s[:items] }
                                                 .select { |i| i[:tier] == :conditional }
    assert_operator conditional.size, :>=, 5, "조건부 판정이 비정상적으로 적다"

    # ⚠️ «배지 문구가 본문에 있다» 로는 부족하다 — 상단 범례에도 같은 문구가 있어서
    #    카드에서 배지를 전부 떼어내도 그 검사는 통과한다(2026-09-20 변형시험 M7 생존).
    #    그래서 **카드에 붙은 배지만** 센다(범례 배지에는 align-middle 이 없다).
    card_badges = body.scan(/align-middle[^>]*>\s*#{Regexp.escape(SchoolOfficeController::CONDITIONAL_BADGE)}/).size
    assert_equal conditional.size, card_badges,
                 "조건부 카드 #{conditional.size}건 중 배지가 붙은 것은 #{card_badges}건"

    conditional.each do |item|
      assert item[:note].present?, "#{item[:path]} 에 조건부 라벨만 있고 사유가 없다"
      assert body.include?(item[:note]), "#{item[:path]} 의 사유가 화면에 없다"
    end
  end

  test "학교 기준 자산에는 조건부 라벨을 붙이지 않는다" do  # 음성 대조 — 전부 노랗게 칠하면 구분이 사라진다
    get school_office_url
    body = response.body

    direct = SchoolOfficeController::SECTIONS.flat_map { |s| s[:items] }.reject { |i| i[:tier] }
    assert_operator direct.size, :>=, 20, "학교 기준 카드가 비정상적으로 적다"
    assert_includes direct.map { |i| i[:path] }, "/topics/school-budget-compilation",
                    "학교회계 예산편성 절차가 학교 기준 카드가 아니다"

    # ⚠️ 상수만 보면 «뷰가 모든 카드에 배지를 붙이는» 결함을 이 검사 단독으로는 못 본다
    #    (2026-09-20 독립 리뷰 F3). 렌더된 카드 조각에서 직접 확인한다.
    checked = 0
    direct.each do |item|
      SchoolOfficeController::SECTIONS.each do |sec|
        idx = body.index(%(next-action-slot-param="#{sec[:id]}:#{item[:path]}"))
        next unless idx

        card_body = body[idx..].split("</a>").first.to_s
        assert_not card_body.include?(SchoolOfficeController::CONDITIONAL_BADGE),
                   "학교 기준 카드 #{item[:path]} 에 조건부 배지가 붙었다"
        checked += 1
      end
    end
    # 검사가 카드를 하나도 못 찾고 «조용히 통과» 하는 것이 바로 이 검사가 막으려는 실패다.
    assert_operator checked, :>=, direct.size, "음성 대조가 카드를 #{checked}건밖에 못 찾았다(대상 #{direct.size})"
  end

  test "집행률 계산기는 학교회계(3월)로 열린다" do
    get school_office_url
    assert response.body.include?("/tools/budget-execution-rate?fy=3"),
           "허브가 집행률 도구를 학교회계 기본값으로 걸지 않는다"

    # 링크가 실제로 3월 선택 상태를 **서버에서** 낸다(JS 없이도 참이어야 한다).
    get "/tools/budget-execution-rate?fy=3"
    assert_response :success
    assert_match(/<option value="3"\s+selected/, response.body,
                 "?fy=3 인데 3월이 선택돼 있지 않다")
  end

  test "적용기관 안내가 «이미 한 일» 을 시키지 않는다" do
    # `?fy=3` 으로 들어오면 3월이 이미 선택돼 있다. 그런데 적용기관 블록이 «3월로 바꿔야» 라고
    # 명령하면 화면이 스스로와 모순된다 — 신뢰를 고치러 온 변경이 새 거짓을 만든다.
    get "/tools/budget-execution-rate?fy=3"
    assert_response :success
    assert_not response.body.include?("3월로 바꿔야"), "이미 3월인데 3월로 바꾸라고 한다"
    assert response.body.include?("3월이어야 경과 월 수가 맞습니다"), "학교회계 차이 설명이 사라졌다"

    get "/tools/budget-execution-rate"   # 지자체 진입에서도 같은 문장이 참이어야 한다
    assert response.body.include?("3월이어야 경과 월 수가 맞습니다")
  end

  test "쿼리가 없으면 지자체 기본값 그대로다" do  # 음성 대조 — 기존 진입점 비회귀
    get "/tools/budget-execution-rate"
    assert_response :success
    assert_match(/<option value="1"\s+selected/, response.body, "무쿼리 기본값이 1월이 아니다")
    assert_no_match(/<option value="3"\s+selected/, response.body, "무쿼리인데 3월이 선택됐다")
  end

  test "잘못된 fy 값은 기본값으로 떨어진다" do
    %w[0 13 abc 3;DROP -3].each do |bad|
      get "/tools/budget-execution-rate", params: { fy: bad }
      assert_response :success
      assert_match(/<option value="1"\s+selected/, response.body, "fy=#{bad} 가 기본값으로 떨어지지 않았다")
    end
  end

  test "학교회계 과목 도구가 없다는 사실을 화면에 적는다" do
    get school_office_url
    body = response.body

    assert_not_includes SchoolOfficeController.all_paths, "/tools/budget-category-finder",
                        "학교회계 과목이 아닌 과목 찾기가 허브에 남아 있다"
    assert body.include?("학교회계 예산과목(세출과목) 찾기 도구는 없습니다"),
           "뺀 도구의 부재를 말하지 않는다 — 사용자는 계속 찾게 된다"
    assert body.include?("학교회계 과목이 아니어서"), "왜 뺐는지가 없다"
  end

  test "학교회계용 과목 도구를 새로 만든 척하지 않는다" do  # 음성 대조
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/tools/school-budget-category-finder", method: :get)
    end
  end

  test "기준 구분을 설명 없이도 알 수 있는 범례가 있다" do
    get school_office_url
    body = response.body
    assert body.include?("학교에서 바로 사용"), "«바로 사용» 범례가 없다"
    assert body.include?("학교 적용 전 확인할 것이 있음"), "조건부 범례가 없다"
    assert body.include?("학교 기준 아님"), "참고자료 범례가 없다"
  end

  test "기존 «다름» 표시는 유지된다" do
    get school_office_url
    body = response.body
    assert body.include?("법정 위원회가 아닙니다"), "물품선정위원회가 법정 기구처럼 보인다"
    assert body.include?("참고선은 산술이며 법정 목표율이 아닙니다"),
           "집행률 참고선이 법정 목표율처럼 보인다"
  end

  test "없는 업무를 «없다» 고 말한다 — 다만 있는 것을 없다고 하지 않는다" do
    get school_office_url
    body = response.body

    assert body.include?("법인카드"), "다루지 않는 업무 안내가 없다"
    # 실제로 있는 결산 토픽을 «없다» 쪽에 넣지 않았는가.
    # (운영 실측 2026-09-18: budget-settlement «결산 절차» sector=common 존재.
    #  test DB 픽스처에는 없으므로 레코드 존재는 여기서 검사하지 않는다 — 운영 스모크가 본다.)
    assert body.include?("결산 절차"), "있는 자산을 없다고 말하고 있다"
    assert body.include?("/topics/budget-settlement"), "결산 링크가 빠졌다"
  end

  test "하단 고정 문구 — 판단 주체와 개인정보 경고" do
    get school_office_url
    body = response.body
    assert body.include?("시도교육청 규칙·지침 원문과 담당자 확인")
    assert body.include?("이름·주민등록번호·급여·학생 정보를 입력하지 마세요")
  end

  test "교육 부문 홈에서 허브로 가는 링크가 있다" do
    get root_url(sector: "edu")
    assert_response :success
    assert response.body.include?(school_office_path),
           "edu 홈에 허브 진입점이 없다 — sector 값이 맞는지 확인하라(edu · education 아님)"
  end

  # ── PHASE B : 축 IA (artifacts/24_SCHOOL_IA_AXIS_JUDGMENT.md) ─────────────
  test "축마다 id 가 있고 내비가 그 축을 전부 가리킨다" do
    get school_office_url
    body = response.body

    ids = SchoolOfficeController::SECTIONS.map { |s| s[:id] }
    assert_equal ids.uniq, ids, "축 id 가 중복됐다 — 앵커가 엉뚱한 곳으로 간다"
    assert ids.none?(&:blank?), "id 가 없는 축이 있다"

    ids.each do |id|
      assert body.include?(%(id="#{id}")), "축 #{id} 에 앵커 대상이 없다"
      assert body.include?(%(href="##{id}")), "축 #{id} 로 가는 내비 링크가 없다"
    end
  end

  test "얇은 축은 얇다고 말한다" do
    get school_office_url
    thin = SchoolOfficeController::SECTIONS.select { |s| s[:thin].present? }
    assert thin.any?, "NEEDS 축 표시가 하나도 없다 — 판정표(24_SCHOOL_IA_AXIS_JUDGMENT)와 어긋난다"
    thin.each do |s|
      assert response.body.include?(s[:thin]), "#{s[:id]} 축의 얇음 표시가 렌더되지 않았다"
    end
  end

  test "자료가 충분한 축에는 얇음 표시를 붙이지 않는다" do  # 음성 대조
    get school_office_url
    fat = SchoolOfficeController::SECTIONS.find { |s| s[:id] == "contract" }
    assert_nil fat[:thin], "계약 축(Topic 57건)에 얇음 표시가 붙었다"
  end

  test "공통 홈에는 허브 링크를 넣지 않는다" do  # 음성 대조
    get root_url(sector: "common")
    assert_response :success
    assert_not response.body.include?("학교 행정실 바로가기 — "),
             "공통 홈까지 학교 전용 진입점이 붙었다"
  end
  # 2026-09-19 연수 대상 감사(33_AUDIENCE_FIT_AUDIT) — 행정실무사(급여·물품) 진입과 정직 표시.
  test "행정실무사 급여·물품 자산이 허브에 있다" do
    paths = SchoolOfficeController.all_paths
    %w[/tools/salary-calculator /tools/insurance-calculator /topics/year-end-settlement
       /review-lab/quote /topics/dual-quote /guides/inspection-report].each do |path|
      assert_includes paths, path, "#{path} 가 허브에서 빠졌다"
    end
  end

  test "재구성 사례에 라벨이 붙고 없는 업무를 정직하게 말한다" do
    get school_office_url
    body = response.body
    assert body.include?("재구성 사례입니다 — 실제 감사결과가 아닙니다"), "병가 재구성 사례에 라벨이 없다"
    assert body.include?("재물조사 도구는 없습니다"), "재물조사 부재 표시가 없다"
    assert body.include?("교육공무직 보수"), "교육공무직 보수 부재 표시가 없다"
    assert body.include?("카드 관련 감사사례"), "있는 카드 감사사례를 없다고만 말한다"
  end

  test "허브 링크 클릭은 기존 next_action_click 으로 계측된다 — 새 이벤트 없음" do
    get school_office_url
    body = response.body
    assert body.include?('data-next-action-topic-slug-value="hub:school-office"'), "계측 컨트롤러가 없다"
    clicks = body.scan(/click-(?:>|&gt;)next-action#track/).size
    # 카드 전부 + 상단 «지금» 배너 1개. 배너를 뺀 자리를 상수로 숨기면 카드 하나가 계측을
    # 잃어도 통과하므로, 추가분은 **여기서 1 이라고 적고** 그 1 의 slot 을 따로 단정한다(P3).
    assert_equal SchoolOfficeController.all_paths.size + 1, clicks, "계측이 붙지 않은 허브 링크가 있다"
    assert body.include?('data-next-action-slot-param="now:/school-office/calendar"'),
           "상단 «지금» 배너에 계측이 없다"
    assert body.include?('data-next-action-slot-param="goods:/review-lab/quote"'), "slot 파라미터 형식이 다르다"

    # P0 — href 에 `?fy=3` 을 붙였다. slot 값까지 같이 바뀌면 기존 GA4 시계열이 끊긴다.
    assert body.include?('data-next-action-slot-param="budget:/tools/budget-execution-rate"'),
           "slot 이 쿼리까지 먹었다 — 기존 next_action_click 값이 바뀐다"
    assert_not body.include?('slot-param="budget:/tools/budget-execution-rate?fy=3"'),
           "slot 에 쿼리스트링이 섞였다"
  end

  test "공개 도구 수 표기는 이 변경으로 줄지 않는다" do  # 39개 registry 비회귀
    # 허브에서 뺀 것이지 도구를 내린 것이 아니다 — /tools 목록과 카운트는 그대로여야 한다.
    assert_equal 39, ApplicationHelper::ACTIVE_TOOL_COUNT
    get "/tools/budget-category-finder"
    assert_response :success, "허브에서 뺀 도구가 직접 진입까지 막혔다"
  end
end
