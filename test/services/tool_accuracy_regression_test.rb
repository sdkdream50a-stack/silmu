require "test_helper"

# 2026-08-04 도구 정확성 P0 교정 회귀 테스트.
# 각 테스트는 교정 전 코드에서 FAIL하도록 경계값을 골랐다.
class ToolAccuracyRegressionTest < ActionDispatch::IntegrationTest
  # ── 연가: 평균 월일수(30.44) 나눗셈이 만 1년을 11개월로 깎던 결함 ──
  test "만 1년 재직은 12개월로 계산되어 연가 12일이 부여된다" do
    data = PdfExportService.annual_leave_data(
      hire_date: "2025-01-01", ref_year: 2026, used_leave: 0
    )
    assert_equal 12, data[:years] * 12 + data[:months], "365일 재직이 11개월로 깎이면 안 된다"
    assert_equal 12, data[:granted]
  end

  test "임용일의 일자가 기준일보다 늦으면 한 달을 빼고 센다" do
    data = PdfExportService.annual_leave_data(
      hire_date: "2025-01-15", ref_year: 2026, used_leave: 0
    )
    assert_equal 11, data[:years] * 12 + data[:months]
  end

  test "임용 전이면 재직 개월수가 0이다" do
    data = PdfExportService.annual_leave_data(
      hire_date: "2027-03-01", ref_year: 2026, used_leave: 0
    )
    assert_equal 0, data[:years] * 12 + data[:months]
  end

  # ── 연가수당: 1일 통상임금에 ×8시간이 빠져 시간급이 일당으로 나가던 결함 ──
  test "1일 통상임금은 월급을 209로 나눈 뒤 8시간을 곱한다" do
    data = PdfExportService.annual_leave_data(
      hire_date: "2020-01-01", ref_year: 2026, used_leave: 0, monthly_wage: 2_090_000
    )
    assert_equal 80_000, data[:ordinary_allowance][:daily_ordinary],
      "월 2,090,000원의 1일 통상임금은 80,000원이다(시간급 10,000원이 아니다)"
  end

  test "형식이 잘못된 임용일은 nil을 돌려준다" do
    assert_nil PdfExportService.annual_leave_data(hire_date: "2026/01/01", ref_year: 2026)
  end

  # ── 지체상금: 일일 금액을 먼저 반올림해 소액 계약에서 오차가 증폭되던 결함 ──
  test "지체상금은 전체식을 계산한 뒤 반올림한다" do
    res = ContractGuaranteeService.calculate_delay_penalty(
      contract_amount: 1001, delay_days: 10, contract_type: "service"
    )
    assert res[:success], res[:error]
    assert_equal 13, res[:result][:total_penalty],
      "1,001원 용역 10일 = 13원. 일일 금액을 먼저 반올림하면 10원이 된다"
  end

  # ── 법정기간: 지급 유형마다 기산일이 다른데 전부 검사완료일로 표기하던 결함 ──
  test "지방자치단체 대금지급의 기산일은 청구일이다" do
    res = LegalPeriodService.calculate(
      period_type: "payment", payment_type: "local", inspection_date: "2026-08-03"
    )
    assert res[:success], res[:error]
    assert_equal "대가 지급 청구일", res[:result][:base_date_name]
    assert_equal 5, res[:result][:days]
  end

  test "국가기관 대금지급도 기산일은 검사완료일이 아니라 청구일이다" do
    res = LegalPeriodService.calculate(
      period_type: "payment", payment_type: "national", inspection_date: "2026-08-03"
    )
    assert_equal "대가 지급 청구일", res[:result][:base_date_name],
      "국가계약법 시행령 제58조도 '청구를 받은 날부터 5일'이다"
    assert_includes res[:result][:note], "청구를 받은 날부터"
  end

  test "지체상금 근거 문구는 지방 기준임을 밝히고 국가 요율을 별도 고지한다" do
    res = LegalPeriodService.calculate(
      period_type: "late_penalty", contract_amount: 1_000_000,
      due_date: "2026-08-01", actual_date: "2026-08-02", penalty_type: "goods"
    )
    assert res[:success], res[:error]
    note = res[:result][:note]
    assert_includes note, "지방계약 기준"
    assert_includes note, "물품(0.75)", "국가계약 물품 요율이 다르다는 사실이 고지되어야 한다"
    assert_includes note, "공사 0.5/1,000로 같지만", "공사는 국가·지방 요율이 같다는 사실도 밝혀야 한다"
  end

  # ── 도구 개수: 상수와 레지스트리가 갈라지던 결함 ──
  test "ACTIVE_TOOL_COUNT는 tools_registry 실제 항목 수와 같다" do
    registry_size = File.read(Rails.root.join("app/helpers/tools_helper.rb")).scan(/\{ title: "/).size
    assert_equal registry_size, ApplicationHelper::ACTIVE_TOOL_COUNT,
      "도구 수 표기(#{ApplicationHelper::ACTIVE_TOOL_COUNT})가 레지스트리(#{registry_size})와 다르다"
  end
  # ── 복수예비가격: ±3% 바깥 정수를 섞던 결함(반올림 방향 반대) ──
  test "추정가격의 복수예비가격은 ±3% 안쪽 정수 15개만 만든다" do
    prices = EstimatedPriceService.send(:generate_multiple_prices, 100_000_000)
    assert_equal 15, prices.size
    assert_equal 15, prices.map { |p| p[:price] }.uniq.size, "15개가 서로 달라야 한다"
    prices.each do |p|
      assert_operator p[:price], :>=, (100_000_000 * 0.97).ceil
      assert_operator p[:price], :<=, (100_000_000 * 1.03).floor
    end
  end

  test "±3% 안에 서로 다른 정수 15개를 만들 수 없으면 빈 배열이다" do
    assert_empty EstimatedPriceService.send(:generate_multiple_prices, 233),
      "233원은 227~239원(13개)이라 15개를 만들 수 없다"
    assert_equal 15, EstimatedPriceService.send(:generate_multiple_prices, 234).size,
      "234원부터 15개가 가능하다"
  end

  # ── 지연배상금 상한: 10%로 적힌 콘텐츠가 곳곳에 남아 있던 결함 ──
  # 열거가 아니라 파생으로 검사한다 — 새 파일이 생겨도 자동으로 걸린다.
  # 제외 파일은 "왜 제외인지"를 함께 고정한다 — 조용한 제외가 검사를 공허하게 만든다.
  CAP_SCAN_EXCLUSIONS = {
    "exam_questions"                          => "시험 문제·오답 선택지라 10%가 정답이 아님",
    "exam_keyword_details"                    => "시험 용어집(계약보증금 10% 설명)",
    "updates.html.erb"                        => "과거 릴리스 기록(당시 서술 보존)",
    "topic_content_fix_2026_08_04_penaltyrates" => "이 오류를 고치는 교정 스크립트 자신",
    "home_quiz_controller"                    => "퀴즈 오답 선택지로 10%를 제시함(정답은 30%)",
    "tool_accuracy_regression_test"           => "이 테스트 자신"
  }.freeze

  test "지연배상금 상한을 10%로 단정한 콘텐츠가 남아 있지 않다" do
    targets = Dir[Rails.root.join("app/**/*.{rb,erb,js}")] + Dir[Rails.root.join("db/seeds/**/*.rb")]
    targets.reject! { |f| CAP_SCAN_EXCLUSIONS.keys.any? { |k| f.include?(k) } }

    # "한도"뿐 아니라 "상한"·"최고 한도"·"초과할 수 없" 표현도 잡는다.
    cap_word     = /상한|한도|초과할 수 없/
    ten_pct      = %r{10\s*%|10/100|100분의 10|10퍼센트}
    # 같은 줄에 올바른 30%가 이미 적혀 있으면 그 10%는 다른 개념(계약보증금·설계변경 등)을 가리킨다.
    states_30    = %r{30\s*%|30/100|100분의 30}

    offenders = targets.filter_map do |file|
      hits = File.read(file).lines.each_with_index.select do |line, _|
        line.match?(/지체상금|지연배상금/) && line.match?(cap_word) &&
          line.match?(ten_pct) && !line.match?(states_30)
      end
      "#{file.sub(Rails.root.to_s + '/', '')}:#{hits.map { |_, i| i + 1 }.join(',')}" if hits.any?
    end

    assert_empty offenders,
      "지연배상금 상한은 계약금액의 30%다(지방계약법 시행령 §90③, 국가계약법 시행령 §74③). 잔존: #{offenders.join(' / ')}"
  end

  # ── 적격심사: 하한 미달 업체를 결과에서 빼버려 미달 확인이 불가능하던 결함 ──
  test "낙찰하한율 미달 업체도 결과에 남아 미달로 표시된다" do
    controller = QualificationEvaluationsController.new
    bidders = [ { name: "A", bid_price: 89_744_999.0 }, { name: "B", bid_price: 95_000_000.0 } ]
    scored = controller.send(:calculate_price_scores, bidders, 100_000_000.0, 89.745, 60)

    assert_equal 2, scored.size, "미달 업체를 목록에서 제거하면 미달 여부를 확인할 수 없다"
    a = scored.find { |b| b[:name] == "A" }
    assert_equal true, a[:below_floor]
    assert_equal false, a[:is_valid]
    assert_equal false, scored.find { |b| b[:name] == "B" }[:below_floor]
  end
  # ── 지방계약법 조문 오기: §17=검사, §18=대가의 지급 (§16=감독, §19=대가의 선납) ──
  # 열거가 아니라 파생으로 검사한다.
  STATUTE_SCAN_EXCLUSIONS = {
    "topic_content_fix_"                  => "과거 오류를 고치는 교정 스크립트들(원본 문자열을 인용함)",
    "exam_questions"                      => "시험 문제·오답 선택지",
    "tool_accuracy_regression_test"       => "이 테스트 자신"
  }.freeze

  test "지방계약법 검사·대가지급 조문을 제16조·제17조로 적은 콘텐츠가 없다" do
    targets = Dir[Rails.root.join("app/**/*.{rb,erb,js}")] + Dir[Rails.root.join("db/seeds/**/*.rb")]
    targets.reject! { |f| STATUTE_SCAN_EXCLUSIONS.keys.any? { |k| f.include?(k) } }

    offenders = targets.filter_map do |file|
      hits = File.read(file).lines.each_with_index.select do |line, _|
        line.match?(/제16조\s*\(?\s*검사/) || line.match?(/제17조\s*\(?\s*대가/)
      end
      "#{file.sub(Rails.root.to_s + '/', '')}:#{hits.map { |_, i| i + 1 }.join(',')}" if hits.any?
    end

    assert_empty offenders,
      "지방계약법은 제17조(검사)·제18조(대가의 지급)다. 잔존: #{offenders.join(' / ')}"
  end

  # ── 적격심사: 낙찰하한율이 비면 0%로 계산돼 모든 투찰이 통과하던 결함 ──
  test "낙찰하한율이 비어 있으면 계산을 거부한다" do
    controller = QualificationEvaluationsController.new
    assert_nil controller.send(:parse_floor_rate, "")
    assert_nil controller.send(:parse_floor_rate, nil)
    assert_nil controller.send(:parse_floor_rate, "0")
    assert_nil controller.send(:parse_floor_rate, "abc")
    assert_nil controller.send(:parse_floor_rate, "101")
    assert_in_delta 89.745, controller.send(:parse_floor_rate, "89.745"), 0.0001
  end
  # ── 지연배상금 한도를 "계약금액 도달"로 서술하던 결함 (30%가 아니라 100%로 읽힘) ──
  test "지연배상금 한도를 계약금액 자체로 서술한 콘텐츠가 없다" do
    targets = Dir[Rails.root.join("app/**/*.{rb,erb,js}")] + Dir[Rails.root.join("db/seeds/**/*.rb")]
    targets.reject! { |f| CAP_SCAN_EXCLUSIONS.keys.any? { |k| f.include?(k) } }
    targets.reject! { |f| f.include?("topic_content_fix_") }

    offenders = targets.filter_map do |file|
      hits = File.read(file).lines.each_with_index.select do |line, _|
        line.match?(/지체상금|지연배상금/) &&
          line.match?(/계약금액에 도달|계약금액을 초과할 수 없|계약금액의 100\s*%/)
      end
      "#{file.sub(Rails.root.to_s + '/', '')}:#{hits.map { |_, i| i + 1 }.join(',')}" if hits.any?
    end

    assert_empty offenders,
      "지연배상금 법정 한도는 계약금액의 30%다. 잔존: #{offenders.join(' / ')}"
  end

  # ── 두 도구가 같은 입력에 다른 지연배상금을 내던 결함(절사 vs 반올림) ──
  test "법정기간 계산기와 계약보증금 계산기의 지연배상금이 일치한다" do
    lp = LegalPeriodService.calculate(
      period_type: "late_penalty", contract_amount: 1000,
      due_date: "2026-08-01", actual_date: "2026-08-06", penalty_type: "service"
    )
    cg = ContractGuaranteeService.calculate_delay_penalty(
      contract_amount: 1000, delay_days: 5, contract_type: "service"
    )
    assert_equal 7, lp[:result][:penalty_amount], "1,000원 용역 5일 = 6.5원 → 7원"
    assert_equal cg[:result][:total_penalty], lp[:result][:penalty_amount],
      "같은 입력에 두 도구가 다른 금액을 내면 안 된다"
  end

  # ── 예정가격 0이면 하한가도 0이 되어 모든 투찰이 "하한 이상"이 되던 결함 ──
  test "예정가격이 없으면 적격심사 계산을 거부한다" do
    post "/qualification-evaluations/evaluate", params: {
      project_type: "construction", estimated_price: "", floor_rate: "89.745",
      bidder_count: 1, bidder_1_name: "A", bidder_1_price: 1_000, bidder_1_non_price: 30
    }
    assert_response :unprocessable_entity
  end

  test "낙찰하한율이 없으면 적격심사 계산을 거부한다" do
    post "/qualification-evaluations/evaluate", params: {
      project_type: "service", estimated_price: 100_000_000, floor_rate: "",
      bidder_count: 1, bidder_1_name: "A", bidder_1_price: 90_000_000, bidder_1_non_price: 30
    }
    assert_response :unprocessable_entity
  end
end
