# frozen_string_literal: true

require "test_helper"

# P1-5 (G-24) — 급여·복무 도구 3종의 «적용 기준·근거» 박스.
#
# 이 도구들은 tool_trust.yml 미등록이라 공통 면책만 떴다. 교육행정직은 **지방공무원**이라
# 국가 규정만 인용하면 근거가 반쪽이다 — 국가·지방을 병기한다.
#
# ⚠️ 근거 배지를 다는 것은 «이 계산을 믿으라» 는 신호다. 그래서 등록 전에
#    03a 가 잡은 계산 결함(연가일수표·직급보조비·정근수당)이 실제로 수리됐는지 먼저 봤고,
#    그 값들을 이 파일에서 함께 고정한다 — 값이 되돌아가면 배지도 같이 거짓이 된다.
class SalaryToolTrustTest < ActionDispatch::IntegrationTest
  REGISTERED = {
    "overtime-calculator"     => :overtime_calculator_url,
    "annual-leave-calculator" => :annual_leave_calculator_url,
    "allowance-calculator"    => :allowance_calculator_url
  }.freeze

  test "급여 도구 3종이 등록부에 있고 근거가 법령 링크로 해석된다" do
    REGISTERED.each_key do |key|
      trust = ToolTrust.for(key)
      assert trust, "#{key} 가 tool_trust.yml 에 없다"
      assert trust.basis.present?, "#{key} 의 basis 가 비었다"

      refs = trust.legal_references
      assert_operator refs.size, :>=, 2, "#{key} 근거가 국가·지방 병기가 아니다"
      refs.each do |r|
        assert_equal "HIGH", r.confidence, "#{key} 의 #{r.raw} 가 해석되지 않았다"
        assert r.official_url.present?, "#{key} 의 #{r.raw} 에 원문 링크가 없다"
      end
      assert refs.any? { |r| r.canonical_name.start_with?("지방공무원") },
             "#{key} 에 지방공무원 근거가 없다 — 교육행정직은 지방공무원이다"
    end
  end

  test "등록하지 않은 도구는 여전히 등록되지 않는다" do  # 음성 대조
    # 기준을 모르는 도구까지 싸잡아 등록하지 않았는가. 연금은 03a 에서 지급률 산정이 OPEN 이다.
    # ToolTrust.for 는 미등록 도구에도 «공통 면책만 든» Info 를 돌려준다(nil 이 아니다).
    # 등록 여부는 basis 유무로 본다 — 이것을 모르고 assert_nil 로 쓰면 항상 실패한다.
    pension = ToolTrust.for("pension-calculator")
    assert_nil pension.basis, "기준이 확정되지 않은 도구까지 등록됐다"
    assert_empty pension.legal_references, "미등록 도구에 근거가 붙었다"
    assert pension.disclaimer.present?, "공통 면책까지 사라졌다"
  end

  test "근거 박스가 화면에 실제로 렌더된다" do
    REGISTERED.each do |key, url_helper|
      get public_send(url_helper)
      assert_response :success
      assert response.body.include?(ToolTrust.for(key).basis),
             "#{key} 화면에 적용 기준이 없다(등록만 되고 렌더되지 않았다)"
    end
  end

  test "존재하지 않는 법령명을 링크로 승격하지 않는다" do
    # G-34 — 「지방공무원 여비 규정」은 law.go.kr 에 없다.
    # resolver 는 모르는 이름도 Reference 로 «싸서» 돌려준다 — 다만 canonical_name·official_url
    # 이 비고 confidence 가 LOW 다. 즉 판정 축은 «항목이 없다» 가 아니라 «승격되지 않았다» 다.
    refs = LegalReferenceResolver.resolve("지방공무원 여비 규정 제16조")
    promoted = refs.select { |r| r.official_url.present? }
    assert_empty promoted, "존재하지 않는 법령이 원문 링크로 승격된다"
    assert refs.none? { |r| r.confidence == "HIGH" },
           "존재하지 않는 법령이 HIGH 신뢰로 표시된다"
    # 양성 대조 — 실재하는 법령은 여전히 승격된다
    ok = LegalReferenceResolver.resolve("공무원 여비 규정 제16조")
    assert ok.any? { |r| r.canonical_name == "공무원 여비 규정" },
           "실재하는 법령까지 해석되지 않는다"
  end

  # ── 배지가 가리키는 계산값이 되돌아가지 않는지 고정한다 (03a P0-2·P0-4·P0-5)
  test "연가 일수표가 2024.7.2 개정값이다" do
    get annual_leave_calculator_url
    body = response.body
    assert body.include?("1년 이상 ~ 3년 미만 → 15일"), "연가 15일(개정값)이 아니다"
    assert body.include?("3년 이상 ~ 4년 미만 → 16일"), "연가 16일(개정값)이 아니다"
    assert_not body.include?("1년 이상 ~ 3년 미만 → 14일"), "개정 전 값이 남아 있다"
  end

  test "직급보조비 8·9급이 175,000원이다" do
    get allowance_calculator_url
    assert response.body.include?("8: 175000, 9: 175000"),
           "직급보조비 8·9급이 개정값(175,000)이 아니다"
  end
end
