# frozen_string_literal: true

require "test_helper"

class ContractDecision::RuleSetTest < ActiveSupport::TestCase
  test "운영 규칙집은 로드되고 모든 rule 이 근거를 갖는다" do
    assert ContractDecision::RuleSet.current.validate!
  end

  # fail-closed 5조건 + 부가 축. 검사가 실제로 잡는지 전건 양성대조한다.
  # "전건 근거 보유"는 검사가 아무것도 안 한 결과일 수도 있다.
  FAIL_CLOSED_CASES = {
    "authority_source 없음"  => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["private_contract_rules"][0].delete("authority_source") } ],
    "source_locator 없음"    => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["private_contract_rules"][0].delete("source_locator") } ],
    "contract_type 불명"     => [ ContractDecision::RuleSet::UnknownContractTypeError,
                                 ->(r) { r["private_contract_rules"][0]["contract_types"] = [ "nope" ] } ],
    "effective_from 없음"    => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["private_contract_rules"][0].delete("effective_from") } ],
    "outcome 없음"           => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["private_contract_rules"][0].delete("outcome") } ],
    "title 없음"             => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["private_contract_rules"][0].delete("title") } ],
    "verified_at 없음"       => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["private_contract_rules"][0].delete("verified_at") } ],
    "agency_scope 불명"      => [ ContractDecision::RuleSet::InvalidRuleError,
                                 ->(r) { r["private_contract_rules"][0]["agency_scope"] = [ "MARS" ] } ],
    "없는 출처 참조"          => [ ContractDecision::RuleSet::UnknownSourceError,
                                 ->(r) { r["private_contract_rules"][0]["authority_source"] = "NOPE" } ],
    "견적 예외 outcome 없음"  => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["quotation_rules"]["single_quote_exceptions"][1].delete("outcome") } ],
    "§28 근거 없음"          => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["split_procurement"]["split_private_contract_permission"].delete("authority_source") } ],
    "기본원칙 근거 없음"      => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["default_procedure"].delete("source_locator") } ],
    "공개의무 근거 없음"      => [ ContractDecision::RuleSet::MissingProvenanceError,
                                 ->(r) { r["disclosure_duty"].delete("authority_source") } ]
  }.freeze

  FAIL_CLOSED_CASES.each do |label, (error_class, mutate)|
    test "fail-closed — #{label}" do
      raw = ContractDecision::RuleSet.current.raw.deep_dup
      mutate.call(raw)
      assert_raises(error_class, "#{label} 를 로딩이 거부하지 않는다") do
        ContractDecision::RuleSet.new(raw).validate!
      end
    end
  end

  test "판정 rule 은 필수 field 9종을 모두 갖는다" do
    rules = ContractDecision::RuleSet.current.private_contract_rules
    rules.each do |r|
      ContractDecision::RuleSet::REQUIRED_RULE_FIELDS.each do |f|
        assert r[f].present?, "#{r['rule_id']} 의 #{f} 가 비어 있다"
      end
    end
    assert_operator rules.size, :>=, 10
  end

  # 양성대조 — 근거를 지우면 검사가 실제로 잡는가.
  # 이걸 확인하지 않으면 "전건 근거 보유"는 검사가 아무것도 안 한 결과일 수 있다.
  test "authority_source 가 없는 rule 은 로딩이 거부된다" do
    raw = ContractDecision::RuleSet.current.raw.deep_dup
    raw["private_contract_rules"].first.delete("authority_source")
    assert_raises(ContractDecision::RuleSet::MissingProvenanceError) do
      ContractDecision::RuleSet.new(raw).validate!
    end
  end

  test "source_locator 가 없는 rule 도 거부된다" do
    raw = ContractDecision::RuleSet.current.raw.deep_dup
    raw["private_contract_rules"].first.delete("source_locator")
    assert_raises(ContractDecision::RuleSet::MissingProvenanceError) do
      ContractDecision::RuleSet.new(raw).validate!
    end
  end

  test "존재하지 않는 출처를 가리키면 거부된다" do
    raw = ContractDecision::RuleSet.current.raw.deep_dup
    raw["private_contract_rules"].first["authority_source"] = "NOT_A_SOURCE"
    assert_raises(ContractDecision::RuleSet::UnknownSourceError) do
      ContractDecision::RuleSet.new(raw).validate!
    end
  end

  test "판정에 인용되는 분리 사유·의무도 근거 검사를 받는다" do
    %w[lawful_separation_grounds planning_duty reporting_duty].each do |key|
      raw = ContractDecision::RuleSet.current.raw.deep_dup
      node = raw["split_procurement"]["construction"][key]
      target = node.is_a?(Array) ? node.first : node
      target.delete("source_locator")
      assert_raises(ContractDecision::RuleSet::MissingProvenanceError, "#{key} 가 검사에서 빠져 있다") do
        ContractDecision::RuleSet.new(raw).validate!
      end
    end
  end

  test "모든 출처는 시행일과 확인일을 갖는다" do
    ContractDecision::RuleSet.current.sources.each do |key, s|
      assert s["effective_from"].present?, "#{key} effective_from 없음"
      assert s["verified_at"].present?,    "#{key} verified_at 없음"
      assert s["url"].present?,            "#{key} url 없음"
    end
  end

  test "적재되지 않은 기관 범위는 이유를 갖는다" do
    ContractDecision::RuleSet.current.agency_scopes.each do |key, s|
      next if s["in_scope"]
      assert s["out_of_scope_reason"].present?, "#{key} 범위 밖 사유 없음"
    end
  end
end
