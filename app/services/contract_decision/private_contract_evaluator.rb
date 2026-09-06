# frozen_string_literal: true

module ContractDecision
  # 수의계약 가능 여부 판정 (지방계약법 시행령 §25①5호) + 견적요건 (§30①).
  #
  # 설계 원칙 3개:
  #   1. 금액만으로 결정하지 않는다. 상대방 자격을 모르면 INSUFFICIENT_INFORMATION 이다.
  #      "모른다"와 "일반업체다"는 다른 입력이고 다른 결론을 낸다.
  #   2. 규칙은 전부 RuleSet(YAML)에서 온다. 이 파일에 금액 리터럴을 두지 않는다.
  #   3. 결과는 언제나 왜 그렇게 나왔는지(matched_rule·legal_basis·unresolved_factors)를
  #      함께 낸다. 근거 없는 점수는 만들지 않는다.
  class PrivateContractEvaluator
    STATES = %w[
      POSSIBLE POSSIBLE_WITH_CONDITIONS COMPETITIVE_PROCEDURE_REQUIRED
      REVIEW_REQUIRED INSUFFICIENT_INFORMATION OUT_OF_SCOPE
    ].freeze

    Result = Struct.new(
      :state, :headline, :quotation, :matched_rule, :legal_basis,
      :conditions, :unresolved_factors, :next_actions, :input, :other_grounds,
      keyword_init: true
    ) do
      def to_h
        { state: state, headline: headline, quotation: quotation,
          matched_rule: matched_rule, legal_basis: legal_basis,
          conditions: conditions, unresolved_factors: unresolved_factors,
          next_actions: next_actions, input: input, other_grounds: other_grounds }
      end
    end

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(agency_scope:, contract_type:, estimated_price:, counterparty_type: nil,
                   special_field: false, vulnerable_ratio_met: nil, rules: RuleSet.current)
      @rules             = rules
      @agency_scope      = agency_scope.presence&.to_s
      @contract_type     = contract_type.presence&.to_s
      @price             = parse_price(estimated_price)
      @counterparty      = counterparty_type.presence&.to_s || "UNKNOWN"
      @special_field     = ActiveModel::Type::Boolean.new.cast(special_field) || false
      @vulnerable_met    = vulnerable_ratio_met.nil? ? nil : ActiveModel::Type::Boolean.new.cast(vulnerable_ratio_met)
      @unresolved        = []
    end

    def call
      scope_problem = check_scope
      return scope_problem if scope_problem

      missing = missing_inputs
      return insufficient(missing) if missing.any?

      candidates = matching_rules
      return competitive if candidates.empty?

      decide(pick(candidates))
    end

    private

    attr_reader :rules, :price, :counterparty

    def parse_price(v)
      return nil if v.blank?
      n = v.to_s.gsub(/[^0-9]/, "")
      n.empty? ? nil : n.to_i
    end

    # ── 기관 범위 ────────────────────────────────────────────────
    def check_scope
      return insufficient([ agency_factor ]) if @agency_scope.blank?

      scope = rules.agency_scope(@agency_scope)
      return insufficient([ agency_factor ]) if scope.nil?
      return nil if scope["in_scope"]

      Result.new(
        state: "OUT_OF_SCOPE",
        headline: "#{scope['label']}는 이 도구가 판단하지 않습니다.",
        quotation: nil, matched_rule: nil,
        legal_basis: [],
        conditions: [],
        unresolved_factors: [ { factor: "AGENCY_SCOPE", detail: scope["out_of_scope_reason"] } ],
        next_actions: [ "해당 기관에 적용되는 계약법령과 내부 계약규정을 확인하세요." ],
        input: input_snapshot, other_grounds: []
      )
    end

    def agency_factor
      { factor: "AGENCY_SCOPE", detail: "어느 기관 기준으로 판단할지 선택해야 합니다. 기관 유형에 따라 적용 법령이 다릅니다." }
    end

    def missing_inputs
      out = []
      out << { factor: "CONTRACT_TYPE", detail: "계약 유형(물품·용역·공사 종류)에 따라 한도가 다릅니다." } if @contract_type.blank? || rules.contract_types[@contract_type].nil?
      out << { factor: "ESTIMATED_AMOUNT", detail: "추정가격이 없으면 금액 요건을 판단할 수 없습니다." } if price.nil? || price <= 0
      # 상대방 자격은 2천만원 초과 물품·용역에서만 결론을 가른다.
      if out.empty? && counterparty == "UNKNOWN" && counterparty_decides?
        out << { factor: "COUNTERPARTY_TYPE",
                 detail: "추정가격 2천만원을 넘는 물품·용역은 계약상대자의 자격(청년창업·소기업·여성기업 등)에 따라 수의계약 가능 여부가 달라집니다. 금액만으로는 결정되지 않습니다." }
      end
      out
    end

    # 상대방 자격이 **결론을 실제로 바꾸는 구간**에서만 묻는다.
    # 결론이 이미 확정되는데도 되물으면 도구가 답을 미루기만 한다.
    #   · 마목(특수분야)은 상대방 무관(any)으로 1억까지 가능하다
    #   · 그 유형의 어떤 rule 로도 닿지 않는 금액이면 상대방과 무관하게 경쟁입찰이다
    def counterparty_decides?
      return false unless goods_service?
      return false if @special_field

      base = rules.private_contract_rules.find { |r| r["rule_id"] == "D25-1-5-나" }
      return false if price > type_ceiling
      price > base["max_amount"]
    end

    # 이 계약 유형에 적용될 수 있는 rule 들의 금액 상한 중 최대값.
    def type_ceiling
      rules.private_contract_rules
           .select { |r| Array(r["contract_types"]).include?(@contract_type) }
           .filter_map { |r| r["max_amount"] }
           .max || 0
    end

    def goods_service?
      rules.contract_types.dig(@contract_type, "family") == "goods_service"
    end

    # ── 규칙 매칭 ────────────────────────────────────────────────
    def matching_rules
      rules.private_contract_rules.select { |r| applies?(r) }
    end

    def applies?(rule)
      return false unless Array(rule["contract_types"]).include?(@contract_type)
      return false if rule["max_amount"] && price > rule["max_amount"]
      return false if rule["min_amount_exclusive"] && price <= rule["min_amount_exclusive"]
      return false if rule["requires_special_field"] && !@special_field
      cp = rule["counterparties"]
      return true if cp == "any"
      Array(cp).include?(counterparty)
    end

    # 여러 rule 이 맞으면 조건이 가장 적은 것(가장 확실한 것)을 고른다.
    def pick(candidates)
      candidates.min_by { |r| [ r["outcome"] == "POSSIBLE" ? 0 : 1, r["max_amount"] || Float::INFINITY ] }
    end

    def decide(rule)
      conditions = Array(rule["conditions"]).dup
      state = rule["outcome"]

      ratio_condition = conditions.find { |c| c.include?("취약계층 고용비율") }

      # 취약계층 고용비율은 **제25조제1항제5호바목 단서**에만 붙는 요건이다.
      # 상대방 종류만 보고 걸면, 그 단서가 없는 나목(2천만 이하)·가목(공사)에서까지
      # 없는 조건을 요구하게 된다 — 실제로 그랬다(사회적기업 1천만원 물품이 조건부로 나왔다).
      # 그래서 **매칭된 rule 이 그 상대방을 명시적으로 조건 삼을 때만** 적용한다.
      if rule_conditions_on_counterparty?(rule) && rules.vulnerable_ratio_required?(counterparty)
        case @vulnerable_met
        when nil
          state = "POSSIBLE_WITH_CONDITIONS"
          @unresolved << { factor: "VULNERABLE_EMPLOYMENT_RATIO",
                           detail: "#{rules.counterparty(counterparty)['label']}는 행정안전부장관 고시 취약계층 고용비율을 충족해야 합니다. 충족 여부가 확인되지 않았습니다." }
        when false
          return competitive(extra_reason: "#{rules.counterparty(counterparty)['label']}의 취약계층 고용비율 요건을 충족하지 못하면 이 수의계약 사유를 적용할 수 없습니다.")
        when true
          # 충족이 확인됐으면 그 조건은 해소됐다. 계속 "조건을 충족할 때에만"이라고 적으면
          # 이미 요건을 갖춘 사용자에게 모순된 안내를 하게 된다.
          conditions.delete(ratio_condition)
        end
      end

      if rule_conditions_on_counterparty?(rule) &&
         (extra = rules.counterparty(counterparty)&.dig("extra_condition"))
        conditions << extra
      end

      state = "POSSIBLE" if state == "POSSIBLE_WITH_CONDITIONS" && conditions.empty? && @unresolved.empty?

      Result.new(
        state: state,
        headline: headline_for(state, rule),
        quotation: QuotationRequirement.call(
          rules: rules, contract_type: @contract_type, price: price,
          counterparty: counterparty, vulnerable_ratio_met: @vulnerable_met
        ),
        matched_rule: rule.slice("rule_id", "source_locator", "outcome"),
        legal_basis: [ rules.citation(rule["authority_source"], rule["source_locator"], quote: rule["quote"]) ],
        conditions: conditions,
        unresolved_factors: @unresolved,
        next_actions: next_actions_for(state),
        input: input_snapshot, other_grounds: other_grounds
      )
    end

    # rule 이 `counterparties: any` 면 상대방 자격을 조건 삼지 않는 조항이다.
    def rule_conditions_on_counterparty?(rule)
      rule["counterparties"] != "any" && Array(rule["counterparties"]).include?(counterparty)
    end

    def competitive(extra_reason: nil)
      Result.new(
        state: "COMPETITIVE_PROCEDURE_REQUIRED",
        headline: "이 금액·유형·상대방 조합에는 시행령 제25조제1항제5호의 수의계약 사유가 적용되지 않습니다. 경쟁입찰이 원칙입니다.",
        quotation: nil, matched_rule: nil,
        legal_basis: [ rules.citation("LOCAL_CONTRACT_ACT", "제9조", quote: "계약은 일반입찰에 부쳐야 한다(단서에 따라 수의계약 가능).") ],
        conditions: [],
        unresolved_factors: @unresolved + (extra_reason ? [ { factor: "COUNTERPARTY_ELIGIBILITY", detail: extra_reason } ] : []),
        next_actions: [
          "경쟁입찰 절차를 검토하세요.",
          "다만 금액 외 수의계약 사유(긴급·경쟁불가·재공고 유찰 등)에 해당할 수 있습니다 — 아래 목록을 확인하고 담당자 검토를 받으세요."
        ],
        input: input_snapshot, other_grounds: other_grounds
      )
    end

    def insufficient(factors)
      Result.new(
        state: "INSUFFICIENT_INFORMATION",
        headline: "지금 입력만으로는 판단할 수 없습니다.",
        quotation: nil, matched_rule: nil, legal_basis: [], conditions: [],
        unresolved_factors: factors,
        next_actions: factors.map { |f| f[:detail] },
        input: input_snapshot, other_grounds: []
      )
    end

    def headline_for(state, rule)
      label = rules.contract_types.dig(@contract_type, "label")
      case state
      when "POSSIBLE"
        "#{label} 추정가격 #{number(price)}원은 #{rule['source_locator']}에 따라 수의계약 대상에 해당합니다."
      when "POSSIBLE_WITH_CONDITIONS"
        "#{label} 추정가격 #{number(price)}원은 아래 조건을 모두 충족할 때에만 #{rule['source_locator']}의 수의계약 대상이 됩니다."
      else
        "검토가 필요합니다."
      end
    end

    def next_actions_for(state)
      base = [ "수의계약 배제사유(부정당업자 제재 등) 해당 여부를 확인하세요." ]
      # 법률 제9조제4항 — 수의계약을 체결하면 내용 공개 의무가 따라붙는다.
      if %w[POSSIBLE POSSIBLE_WITH_CONDITIONS].include?(state)
        duty = rules.raw["disclosure_duty"]
        base << "수의계약을 체결하면 그 내용을 공개해야 합니다 (#{duty['source_locator']})."
      end
      state == "POSSIBLE_WITH_CONDITIONS" ? [ "위 조건의 충족 여부를 증빙으로 확인하고 그 근거를 계약서류에 남기세요." ] + base : base
    end

    def other_grounds = rules.non_amount_grounds

    def input_snapshot
      { agency_scope: @agency_scope, contract_type: @contract_type,
        estimated_price: price, counterparty_type: counterparty,
        special_field: @special_field, vulnerable_ratio_met: @vulnerable_met }
    end

    def number(n) = n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
