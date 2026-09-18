# frozen_string_literal: true

require "test_helper"

# G-65 (2026-09-18) — 카드에도 출처 유형이 붙는가.
#
# 상세 페이지에는 `shared/_provenance_banner` 가 있었지만 **카드에는 없었다**.
# 운영 실측: 홈 감사사례 카드 재구성 고지 0회. 카드만 보고 나가는 사용자가
# 재구성·가상 사례를 실제 감사 사건으로 읽는다.
#
# 이 테스트는 등록부가 아니라 **렌더된 응답**을 본다.
class AuditCaseCardProvenanceTest < ActionDispatch::IntegrationTest
  # ⚠️ 첫 판본은 본문에 "재구성" 이 있는지만 봤다. 목록 상단 안내문에 이미
  #    「공개 자료를 재구성한 사례」라는 문장이 있어서 **수리 전에도 통과**했다
  #    (2026-09-18 자기 결함 — artifact 23 §4 2번과 같은 부분문자열 오탐).
  #    그래서 안내문이 아니라 «칩» 자체를 센다.
  CHIP = /<span class="material-symbols-outlined text-\[12px\] leading-none" aria-hidden="true">/

  test "재구성 사례 카드에는 목록에서도 출처 칩이 붙는다" do
    ac = AuditCase.published.first
    ac.update!(source_type: "SILMU_RECONSTRUCTED_CASE", is_reconstructed: true)

    get audit_cases_url
    assert_response :success

    chips = response.body.scan(CHIP).size
    assert_operator chips, :>, 0,
                    "목록 카드에 출처 칩이 하나도 없다 — 카드만 보면 실제 감사 사건과 구별되지 않는다"
    # 양성 대조 — 칩이 «재구성» 을 말하는가(안내문 문장이 아니라 칩 안의 글자)
    assert response.body.match?(/#{CHIP.source}draw<\/span>\s*재구성/),
           "칩은 있는데 재구성 표기가 아니다"
  end

  test "원문 근거가 있는 사례에는 칩을 붙이지 않는다" do  # 음성 대조
    AuditCase.published.find_each do |c|
      c.update_columns(source_type: "ACTUAL_AUDIT",
                       is_reconstructed: false,
                       source_url: "https://example.org/audit.pdf")
    end

    get audit_cases_url
    assert_response :success
    assert_not response.body.include?(">재구성"),
             "원문 근거가 있는 사례에까지 재구성 칩이 붙었다"
    assert_not response.body.include?("출처 확인 필요"),
             "원문 근거가 있는 사례에 출처 확인 필요가 붙었다"
  end

  test "출처 미확정 사례는 «출처 확인 필요» 로 구별된다" do
    ac = AuditCase.published.first
    ac.update_columns(source_type: nil, is_reconstructed: false, source_url: nil, source: {})

    get audit_cases_url
    assert_response :success
    assert response.body.include?("출처 확인 필요"),
           "출처 미확정 사례가 원문 근거 사례와 화면에서 같아 보인다"
  end

  test "칩과 상세 배너가 같은 원장을 읽는다" do
    ac = AuditCase.published.first
    ac.update!(source_type: "SILMU_SIMULATED_CASE", is_reconstructed: false)

    assert ac.reconstructed_case?,
           "SILMU_SIMULATED_CASE 는 RECONSTRUCTED_TYPES 다 — 칩이 이 판정을 그대로 쓴다"

    get audit_case_url(slug: ac.slug)
    assert_response :success
    assert response.body.include?(ac.provenance_label),
           "상세 배너가 사라졌다(카드 작업이 배너를 깨뜨렸다)"
  end
end
