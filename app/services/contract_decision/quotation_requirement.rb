# frozen_string_literal: true

module ContractDecision
  # 견적 요건 (시행령 §30①). 수의계약 "가능 여부"(§25)와는 **다른 판단**이다.
  # 두 축을 한 문자열로 합치면 "5천만원까지 수의계약 가능"처럼 §25 한도와
  # §30 견적요건이 섞인 문장이 나온다 — 실제로 그렇게 섞여 있었다.
  class QuotationRequirement
    Result = Struct.new(:requirement, :label, :legal_basis, :conditions, :notes, keyword_init: true) do
      def to_h = { requirement: requirement, label: label, legal_basis: legal_basis,
                   conditions: conditions, notes: notes }
    end

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(rules:, contract_type:, price:, counterparty:, vulnerable_ratio_met: nil)
      @rules = rules
      @contract_type = contract_type
      @price = price
      @counterparty = counterparty
      @vulnerable_met = vulnerable_ratio_met
    end

    def call
      exception = single_quote_exception
      return two_or_more if exception.nil?

      Result.new(
        requirement: "SINGLE_ALLOWED",
        label: "1인 견적으로 할 수 있습니다 (2인 이상이 원칙, 이 경우는 예외)",
        legal_basis: [ @rules.citation(exception["authority_source"], exception["source_locator"], quote: exception["quote"]) ],
        conditions: Array(exception["conditions"]),
        notes: waiver_note
      )
    end

    private

    def single_quote_exception
      @rules.quotation_rules["single_quote_exceptions"].find do |ex|
        next false unless ex["trigger"] == "AMOUNT"
        next false unless Array(ex["contract_types"]).include?(@contract_type)
        next false if ex["max_amount"] && @price > ex["max_amount"]
        cp = ex["counterparties"]
        next true if cp == "any"
        next false unless Array(cp).include?(@counterparty)
        # 취약계층 고용비율 미충족이 확인되면 이 예외는 적용되지 않는다.
        !(@rules.vulnerable_ratio_required?(@counterparty) && @vulnerable_met == false)
      end
    end

    def two_or_more
      d = @rules.quotation_rules["default"]
      ds = @rules.quotation_rules["designated_system"]
      Result.new(
        requirement: "TWO_OR_MORE",
        label: "2인 이상으로부터 견적서를 받아야 합니다",
        legal_basis: [ @rules.citation(d["authority_source"], d["source_locator"], quote: d["quote"]),
                       @rules.citation(ds["authority_source"], ds["source_locator"], quote: ds["quote"]) ],
        conditions: [],
        notes: [ "2인 이상 견적은 지정정보처리장치(나라장터·학교장터 등)를 이용해야 합니다." ] + waiver_note
      )
    end

    def waiver_note
      w = @rules.quotation_rules["quote_waiver"]
      return [] unless Array(w["contract_types"]).include?(@contract_type)
      return [] unless @price < w["max_amount_exclusive"]

      [ "추정가격 200만원 미만 물품·용역은 견적서 제출을 생략할 수 있습니다 (#{w['source_locator']}). #{w['note']}" ]
    end
  end
end
