# frozen_string_literal: true

module ContractDecision
  # config/contract_decision_rules.yml 로더.
  #
  # 이 클래스가 강제하는 단 하나의 불변식: **근거 없는 rule 은 존재할 수 없다.**
  # authority_source 나 source_locator 가 빠진 rule 이 있으면 로딩 자체가 실패한다.
  # 조용히 건너뛰면 "공식 기준"이라고 표시되는 근거 없는 값이 생긴다.
  class RuleSet
    class MissingProvenanceError < StandardError; end
    class UnknownSourceError < StandardError; end
    class UnknownContractTypeError < StandardError; end
    class InvalidRuleError < StandardError; end

    # 판정에 쓰이는 rule 이 반드시 가져야 하는 field.
    # 하나라도 없으면 로딩이 실패한다 — 근거 없는 편의 rule 을 만들지 않기 위해서다.
    REQUIRED_RULE_FIELDS = %w[
      rule_id title agency_scope condition outcome
      authority_source source_locator effective_from verified_at
    ].freeze

    PATH = "config/contract_decision_rules.yml"

    class << self
      def current = (@current ||= load!)
      def reload! = (@current = load!)

      def load!(path = Rails.root.join(PATH))
        new(YAML.load_file(path, permitted_classes: [ Date ], aliases: false)).tap(&:validate!)
      end
    end

    attr_reader :raw

    def initialize(raw) = @raw = raw.deep_dup.freeze

    def meta               = raw["meta"]
    def sources            = raw["sources"]
    def agency_scopes      = raw["agency_scopes"]
    def contract_types     = raw["contract_types"]
    def counterparty_types = raw["counterparty_types"]
    def private_contract_rules = raw["private_contract_rules"]
    def non_amount_grounds = raw["non_amount_grounds"]
    def quotation_rules    = raw["quotation_rules"]
    def split_procurement  = raw["split_procurement"]

    # `def source(key) = h[k] or raise(...)` 로 쓰면 `or` 가 def 전체에 걸려
    # raise 가 영원히 실행되지 않는다. 검사처럼 보이지만 아무것도 막지 않는다.
    def source(key)
      sources.fetch(key.to_s) { raise UnknownSourceError, "알 수 없는 출처: #{key}" }
    end

    # 화면·API 가 근거를 표시할 때 쓰는 단일 형태.
    def citation(source_key, locator, quote: nil)
      s = source(source_key)
      { source_key: source_key, title: s["title"], short: s["short"],
        locator: locator, quote: quote,
        effective_from: s["effective_from"], verified_at: s["verified_at"], url: s["url"] }
    end

    def agency_scope(key) = agency_scopes[key.to_s]
    def counterparty(key) = counterparty_types[key.to_s]

    # 취약계층 고용비율 고시를 충족해야 하는 상대방인지.
    def vulnerable_ratio_required?(key)
      counterparty(key)&.dig("requires_vulnerable_employment_ratio") == true
    end

    # fail-closed. 조용히 건너뛰면 "공식 기준"이라고 표시되는 근거 없는 값이 생긴다.
    def validate!
      provenance_bearing_rules.each do |rule|
        id = rule["rule_id"] || rule.inspect

        missing = REQUIRED_RULE_FIELDS.reject { |f| rule[f].present? }
        raise MissingProvenanceError, "rule #{id} — 필수 field 누락: #{missing.join(', ')}" if missing.any?

        # 출처 key 가 실재해야 한다.
        source(rule["authority_source"])

        # contract_types 를 선언했다면 registry 에 있는 유형이어야 한다.
        # 오타 하나로 rule 이 조용히 아무 계약에도 매칭되지 않는 것을 막는다.
        Array(rule["contract_types"]).each do |t|
          next if contract_types.key?(t.to_s)

          raise UnknownContractTypeError, "rule #{id} — 알 수 없는 contract_type: #{t}"
        end

        # agency_scope 도 registry 대조.
        Array(rule["agency_scope"]).each do |a|
          next if agency_scopes.key?(a.to_s)

          raise InvalidRuleError, "rule #{id} — 알 수 없는 agency_scope: #{a}"
        end
      end

      cited_fragments.each do |frag|
        id = frag["ground_id"] || frag["source_locator"] || frag.inspect
        %w[authority_source source_locator].each do |f|
          raise MissingProvenanceError, "인용 항목 #{id} — #{f} 누락" if frag[f].blank?
        end
        source(frag["authority_source"])
      end

      self
    end

    private

    # 판단에 실제로 쓰이는 rule 만 모은다. 목록(non_amount_grounds)처럼
    # 안내용 항목은 상위 블록이 근거를 갖는다.
    def provenance_bearing_rules
      [ raw["default_procedure"] ] +
        private_contract_rules +
        quotation_rules["single_quote_exceptions"] +
        [ quotation_rules["default"], quotation_rules["designated_system"], quotation_rules["quote_waiver"] ] +
        [ split_procurement.dig("construction", "prohibition"),
          split_procurement.dig("construction", "avoidance_override"),
          split_procurement["goods_service"],
          split_procurement["split_private_contract_permission"] ]
    end

    # 의무·분리사유는 판정 결과에 조문으로 표시되지만 rule 스키마(outcome 등)를 갖지 않는다.
    # 그래서 별도 불변식을 받는다 — 근거는 반드시 있어야 하고, 출처 key 도 실재해야 한다.
    def cited_fragments
      [ split_procurement.dig("construction", "planning_duty"),
        split_procurement.dig("construction", "reporting_duty"),
        raw["disclosure_duty"] ] +
        split_procurement.dig("construction", "lawful_separation_grounds")
    end
  end
end
