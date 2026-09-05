# frozen_string_literal: true

require "test_helper"

# P1-5 §18·§19 — 도구 신뢰 레이어.
class ToolTrustTest < ActiveSupport::TestCase
  test "등록된 도구는 적용기준·기준일·근거를 갖는다" do
    info = ToolTrust.for("contract-method")
    assert info.any_basis?
    assert info.basis.present?
    assert_match(/\A\d{4}-\d{2}-\d{2}\z/, info.standard_version,
                 "기준일이 설정 파일에서 읽히지 않음")
    assert info.legal_references.any?(&:resolved?), "근거 법령이 링크로 승격되지 않음"
  end

  test "기준일은 설정 파일에서 직접 읽는다 (손으로 적지 않는다)" do
    # config/contract_thresholds.yml 헤더의 최종 갱신일과 일치해야 한다
    raw = File.read(Rails.root.join("config", "contract_thresholds.yml"))
    expected = raw[/마지막 업데이트:\s*(\d{4}-\d{2}-\d{2})/, 1]
    assert_equal expected, ToolTrust.for("contract-method").standard_version

    expected_legal = YAML.safe_load(File.read(Rails.root.join("config", "legal_standards.yml")))["version"]
    assert_equal expected_legal, ToolTrust.for("travel-calculator").standard_version
  end

  test "등록되지 않은 도구는 근거를 지어내지 않는다" do
    info = ToolTrust.for("pdf")
    refute info.any_basis?, "미등록 도구에 근거가 생성됨"
    assert_nil info.basis
    assert_nil info.standard_version
    assert_empty info.legal_references
  end

  test "모든 도구가 면책 문구를 갖는다 (등록 여부와 무관)" do
    %w[contract-method pdf task-calendar 존재하지-않는-도구].each do |key|
      assert ToolTrust.for(key).disclaimer.present?, "#{key} 에 면책 문구 없음"
      assert_includes ToolTrust.for(key).disclaimer, "실무 참고용"
    end
  end

  test "tool: 접두어가 붙어도 동일하게 해석한다" do
    assert_equal ToolTrust.for("contract-method").basis, ToolTrust.for("tool:contract-method").basis
  end
end
