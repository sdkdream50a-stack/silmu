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

  test "학교회계 기준이 아닌 자산에는 그 사실이 붙는다" do
    get school_office_url
    body = response.body

    # 예산 도구 3종은 지자체 기준이다 — 감사 시점에는 «제외» 였고 R1 수리 후 «표시하고 포함» 으로 바꿨다.
    assert body.include?(SchoolOfficeController::LOCALGOV_NOTE),
           "지자체 기준 자산에 구분 표시가 없다"
    assert body.include?("회계연도 시작월을 3월(학교회계)로"),
           "집행률 도구의 학교회계 사용법 안내가 없다"
    assert body.include?("법정 위원회가 아닙니다"),
           "물품선정위원회가 법정 기구처럼 보인다"
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
    assert_equal SchoolOfficeController.all_paths.size, clicks, "계측이 붙지 않은 허브 링크가 있다"
    assert body.include?('data-next-action-slot-param="goods:/review-lab/quote"'), "slot 파라미터 형식이 다르다"
  end
end
