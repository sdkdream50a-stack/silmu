require "test_helper"

# 법정기간 계산기는 공무원 실무 판단의 기준 — 법령 인용값이 변경되면 이 테스트가 먼저 깨져서
# 명시적 검토를 강제해야 한다. 각 분기에 근거 법령을 주석으로 기록.
class LegalPeriodServiceTest < ActiveSupport::TestCase
  test "invalid period_type returns error" do
    result = LegalPeriodService.calculate(period_type: "unknown")
    assert_equal false, result[:success]
    assert result[:error].present?
  end

  # === 입찰공고기간 (국가계약법 시행령 제33조) ===
  test "announcement: 10억 미만 → 7일" do
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 500_000_000,
      announcement_date: "2026-05-04" # 월요일
    )
    assert result[:success]
    assert_equal 7, result[:result][:days]
    assert_match(/10억 미만/, result[:result][:period_label])
  end

  test "announcement: 10억~50억 → 15일" do
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 2_000_000_000,
      announcement_date: "2026-05-04"
    )
    assert_equal 15, result[:result][:days]
  end

  test "announcement: 50억~265억 → 30일" do
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 10_000_000_000,
      announcement_date: "2026-05-04"
    )
    assert_equal 30, result[:result][:days]
  end

  test "announcement: 265억 이상 → 40일 (WTO 고시금액)" do
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 30_000_000_000,
      announcement_date: "2026-05-04"
    )
    assert_equal 40, result[:result][:days]
  end

  test "announcement: 긴급입찰이면 금액 무관 5일" do
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 30_000_000_000,
      announcement_date: "2026-05-04",
      urgent: "true"
    )
    assert_equal 5, result[:result][:days]
    assert result[:result][:urgent]
  end

  test "announcement: 공고일 누락이면 error" do
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 500_000_000,
      announcement_date: ""
    )
    assert_equal false, result[:success]
  end

  # === 주말 자동 조정 (RFC 없음, 실무 관행) ===
  test "weekend end_date lands on Monday" do
    # 2026-05-04(월) + 5일 = 2026-05-09(토) → 월요일(2026-05-11)로 조정
    result = LegalPeriodService.calculate(
      period_type: "announcement",
      estimated_amount: 500_000_000,
      announcement_date: "2026-05-04",
      urgent: "true"
    )
    assert_equal "2026-05-11", result[:result][:end_date]
    assert_equal "월요일", result[:result][:end_weekday]
  end

  # === 계약체결기한 (국가계약법 시행령 제49조) ===
  test "contract_signing: 낙찰통지 후 10일" do
    result = LegalPeriodService.calculate(
      period_type: "contract_signing",
      notification_date: "2026-05-04" # 월요일
    )
    assert result[:success]
    assert_equal 10, result[:result][:days]
    assert_equal "2026-05-14", result[:result][:deadline]
  end

  # === 대금지급 (국가계약법 시행령 제58조, 지방계약법 제17조) ===
  test "payment: national → 5일" do
    result = LegalPeriodService.calculate(
      period_type: "payment",
      payment_type: "national",
      inspection_date: "2026-05-04"
    )
    assert_equal 5, result[:result][:days]
    assert_equal "2026-05-11", result[:result][:deadline] # +5 = 토 → 월
  end

  test "payment: subcontract → 15일 (하도급법 제13조)" do
    result = LegalPeriodService.calculate(
      period_type: "payment",
      payment_type: "subcontract",
      inspection_date: "2026-05-04"
    )
    assert_equal 15, result[:result][:days]
  end

  test "payment: 잘못된 지급유형이면 error" do
    result = LegalPeriodService.calculate(
      period_type: "payment",
      payment_type: "unknown",
      inspection_date: "2026-05-04"
    )
    assert_equal false, result[:success]
  end

  # === 하자담보 (국가계약법 시행령 제70조, 지방계약법 시행령 제78조) ===
  test "defect_warranty: 구조체 공사 5년" do
    result = LegalPeriodService.calculate(
      period_type: "defect_warranty",
      completion_date: "2026-05-01",
      work_types: [ "structure" ]
    )
    assert result[:success]
    warranty = result[:result][:warranties].first
    assert_equal 5, warranty[:years]
    assert_equal "2031-05-01", warranty[:end_date]
  end

  test "defect_warranty: 여러 공종 동시 조회" do
    result = LegalPeriodService.calculate(
      period_type: "defect_warranty",
      completion_date: "2026-05-01",
      work_types: [ "structure", "painting", "electrical" ]
    )
    assert_equal 3, result[:result][:warranties].size
  end

  test "defect_warranty: 공종 미선택이면 error" do
    result = LegalPeriodService.calculate(
      period_type: "defect_warranty",
      completion_date: "2026-05-01",
      work_types: []
    )
    assert_equal false, result[:success]
  end

  # === 지체상금 (지방계약법 시행규칙 제75조) ===
  test "late_penalty: 공사 10일 지체시 0.5/1000 × 계약금액 × 지체일수" do
    # 1억 × 0.5/1000 × 10일 = 500,000원
    result = LegalPeriodService.calculate(
      period_type: "late_penalty",
      penalty_type: "construction",
      contract_amount: 100_000_000,
      due_date: "2026-05-01",
      actual_date: "2026-05-11"
    )
    assert result[:success]
    assert_equal 10, result[:result][:delay_days]
    assert_equal 500_000, result[:result][:penalty_amount]
  end

  test "late_penalty: 기한내 이행시 0원" do
    result = LegalPeriodService.calculate(
      period_type: "late_penalty",
      penalty_type: "construction",
      contract_amount: 100_000_000,
      due_date: "2026-05-10",
      actual_date: "2026-05-05"
    )
    assert_equal 0, result[:result][:delay_days]
    assert_equal 0, result[:result][:penalty_amount]
  end

  test "late_penalty: 계약금액의 10% 상한 (지방계약법 시행규칙 제75조 단서)" do
    # 100만원 계약, 공사 1000일 지체 → 500만원 계산되지만 10만원 cap
    result = LegalPeriodService.calculate(
      period_type: "late_penalty",
      penalty_type: "construction",
      contract_amount: 1_000_000,
      due_date: "2026-01-01",
      actual_date: "2028-10-01" # 1000+일 지체
    )
    assert result[:result][:capped], "10% 상한에 걸려야 함"
    assert_equal 100_000, result[:result][:penalty_amount]
  end

  test "late_penalty: 용역 요율 1.3/1000" do
    # 1억 × 1.3/1000 × 10일 = 1,300,000원
    result = LegalPeriodService.calculate(
      period_type: "late_penalty",
      penalty_type: "service",
      contract_amount: 100_000_000,
      due_date: "2026-05-01",
      actual_date: "2026-05-11"
    )
    assert_equal 1_300_000, result[:result][:penalty_amount]
  end
end
