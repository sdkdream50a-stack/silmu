# frozen_string_literal: true

module ContractDecision
  # 분할발주 판단.
  #
  # 공사와 물품·용역은 **법적 구조가 다르다.** 하나의 규칙으로 합치지 않는다.
  #
  #   공사      시행령 §77①  — 전체 사업내용이 확정된 동일 구조물·단일공사의
  #                            시기적/공사량 분할을 금지. 다만 §77①1~3호는 허용.
  #                            §77③ — 허용 사유가 있어도 수의계약 회피 목적이면 안 된다.
  #   물품·용역  시행령 §7제2호 — "금지"가 아니라 추정가격 **합산 산정** 규칙이다.
  #                            분할되어 이루어지는 계약은 직전/직후 12개월 또는
  #                            해당 회계연도 총액을 추정가격으로 본다.
  #
  # 이 구분이 중요한 이유: 물품·용역에 §77 을 근거로 대면 조문을 잘못 인용하는 것이고,
  # 합산 규칙을 놓치면 "나눠 샀으니 각각 2천만원 이하"라는 오판을 그대로 통과시킨다.
  class SplitProcurementEvaluator
    STATES = %w[
      LOW_RISK REVIEW_NEEDED HIGH_SPLIT_RISK
      LEGITIMATE_SEPARATION_POSSIBLE INSUFFICIENT_INFORMATION
    ].freeze

    # 조문 요건에 대응하는 사실 질문. 각 답은 yes | no | unknown 이다.
    # "체크박스 개수"로 점수를 내지 않는다 — 조문에 그런 기준이 없다.
    CONSTRUCTION_FACTORS = {
      single_project: "제77조제1항",         # 동일 구조물공사 또는 단일공사인가
      scope_fixed:    "제77조제1항",         # 설계서 등으로 전체 사업내용이 확정되었는가
      avoidance_intent: "제77조제3항"        # 수의계약 한도·경쟁을 회피하려는 분할인가
    }.freeze

    GOODS_SERVICE_FACTORS = {
      same_purpose: "제7조제2호",            # 동일·유사한 조달 요구인가
      within_window: "제7조제2호"            # 12개월/회계연도 합산 대상 기간 안인가
    }.freeze

    Result = Struct.new(
      :state, :headline, :track, :matched_rule, :legal_basis, :aggregation,
      :lawful_separation_grounds, :duties, :unresolved_factors, :next_actions, :input, :review_axes,
      keyword_init: true
    ) do
      def to_h
        { state: state, headline: headline, track: track, matched_rule: matched_rule,
          legal_basis: legal_basis, aggregation: aggregation,
          lawful_separation_grounds: lawful_separation_grounds, duties: duties,
          unresolved_factors: unresolved_factors, next_actions: next_actions, input: input,
          review_axes: review_axes }
      end
    end

    def self.call(**kwargs) = new(**kwargs).call

    # factors: 위 FACTORS 키 → "yes" | "no" | "unknown"
    # separation_ground: §77①1~3호 중 주장하는 사유의 ground_id (없으면 nil)
    def initialize(contract_type:, factors: {}, separation_ground: nil,
                   current_amount: nil, prior_amounts: [], rules: RuleSet.current)
      @rules   = rules
      @type    = contract_type.presence&.to_s
      # 넘어오지 않은 요건은 "미상"이다. nil 로 두면 아래 분기가 "yes 도 no 도 아님"으로
      # 흘러가 정보가 없는데 결론이 나온다.
      given = (factors || {}).to_h { |k, v| [ k.to_s, normalize(v) ] }
      @factors = all_factor_keys.index_with { |k| given.fetch(k, "unknown") }
      @ground  = separation_ground.presence&.to_s
      @current = to_amount(current_amount)
      @priors  = Array(prior_amounts).map { |a| to_amount(a) }.compact
      @unresolved = []
    end

    def call
      return insufficient([ { factor: "CONTRACT_TYPE", detail: "계약 유형을 선택해야 어느 조문이 적용되는지 정해집니다. 공사와 물품·용역은 근거 조문이 다릅니다." } ]) if family.nil?

      family == "construction" ? evaluate_construction : evaluate_goods_service
    end

    private

    attr_reader :rules

    def all_factor_keys
      (CONSTRUCTION_FACTORS.keys + GOODS_SERVICE_FACTORS.keys).map(&:to_s)
    end

    def normalize(v)
      s = v.to_s.downcase
      return "yes" if %w[yes true 1 y].include?(s)
      return "no"  if %w[no false 0 n].include?(s)
      "unknown"
    end

    def to_amount(v)
      return nil if v.blank?
      n = v.to_s.gsub(/[^0-9]/, "")
      n.empty? ? nil : n.to_i
    end

    def family = rules.contract_types.dig(@type, "family")

    # ── 공사 트랙 (§77) ─────────────────────────────────────────
    def evaluate_construction
      cfg   = rules.split_procurement["construction"]
      prohib = cfg["prohibition"]
      basis = [ rules.citation(prohib["authority_source"], prohib["source_locator"], quote: prohib["quote"]) ]

      ground = lawful_grounds.find { |x| x["ground_id"] == @ground }
      prohibited_shape = @factors["single_project"] == "yes" && @factors["scope_fixed"] == "yes"

      # ① 회피 목적 — §77③ 은 **제1항 각 호의 공사**에 붙는 조항이다. 그래서 그 조항을 근거로
      #    들려면 분리 사유를 주장했거나 §77① 요건이 성립해야 한다. 아무것도 성립하지 않은
      #    상태에서 "회피 목적"만 보고 §77③ 을 인용하면 조문 적용범위를 넘어선다.
      shape_definitely_absent = @factors["single_project"] == "no" || @factors["scope_fixed"] == "no"

      # ⓪ 금지 요건이 **확정적으로** 미충족이면 §77 이 애초에 적용되지 않는다.
      #    회피 목적 답변보다 먼저 본다 — 조문이 적용되지 않는데 그 조문 위반이라고 할 수는 없다.
      #    다만 "별개 사업인데 회피 목적"은 서로 맞지 않는 답이므로 그대로 짚는다.
      if shape_definitely_absent
        return not_prohibited(cfg, basis) unless @factors["avoidance_intent"] == "yes"

        return Result.new(
          state: "REVIEW_NEEDED",
          headline: "입력이 서로 맞지 않습니다 — 별개 사업이라면 회피할 한도가 없고, 회피 목적이 있다면 별개 사업이 아닐 수 있습니다.",
          track: "CONSTRUCTION",
          matched_rule: { rule_id: "D77-1", source_locator: cfg.dig("prohibition", "source_locator") },
          legal_basis: basis, aggregation: nil,
          lawful_separation_grounds: lawful_grounds, duties: duties(cfg),
          unresolved_factors: @unresolved + [
            { factor: "INCONSISTENT_INPUT",
              detail: "동일 구조물·단일공사가 아니라고 답했는데 수의계약 한도 회피 목적이 있다고도 답했습니다. 사업계획·설계서로 사실관계를 먼저 확정하세요." }
          ],
          next_actions: [ "사업의 동일성 여부를 예산편성·기본설계 자료로 확인하세요 (제77조제2항).",
                          "동일 사업이라면 통합 발주 또는 경쟁입찰을 검토하세요." ],
          input: input_snapshot, review_axes: review_axes
        )
      end

      if @factors["avoidance_intent"] == "yes" && !prohibited_shape && !ground
        return Result.new(
          state: "REVIEW_NEEDED",
          headline: "회피 목적이라고 입력했지만, 제77조제1항의 금지 요건도 각 호의 분리 사유도 확인되지 않았습니다. 사실관계를 먼저 확정해야 합니다.",
          track: "CONSTRUCTION", matched_rule: nil,
          legal_basis: basis, aggregation: nil,
          lawful_separation_grounds: lawful_grounds, duties: duties(cfg),
          unresolved_factors: @unresolved + unknown_factors(CONSTRUCTION_FACTORS) + [
            { factor: "AVOIDANCE_SCOPE",
              detail: "제77조제3항은 제77조제1항 각 호에 해당하는 공사에 적용됩니다. 이 계약이 동일 구조물·단일공사인지, 각 호의 분리 사유가 있는지부터 확인하세요." }
          ],
          next_actions: [ "동일 구조물·단일공사 여부와 전체 사업내용 확정 여부를 사업계획·설계서로 확인하세요.",
                          "확인 결과에 따라 통합 발주 또는 경쟁입찰을 검토하세요." ],
          input: input_snapshot, review_axes: review_axes
        )
      end

      if @factors["avoidance_intent"] == "yes"
        ov = cfg["avoidance_override"]
        return Result.new(
          state: "HIGH_SPLIT_RISK",
          headline: "수의계약 한도나 경쟁을 회피할 목적의 분할은 허용되지 않습니다. 분리 사유가 따로 있더라도 그렇습니다.",
          track: "CONSTRUCTION", matched_rule: { rule_id: "D77-3", source_locator: ov["source_locator"] },
          legal_basis: basis + [ rules.citation(ov["authority_source"], ov["source_locator"], quote: ov["quote"]) ],
          aggregation: nil, lawful_separation_grounds: lawful_grounds, duties: duties(cfg),
          unresolved_factors: @unresolved, next_actions: [ "통합 발주 또는 경쟁입찰로 전환하고, 검토 경위를 문서로 남기세요." ],
          input: input_snapshot, review_axes: review_axes
        )
      end

      # ② 적법한 분리 사유를 주장하면 그 사유를 근거와 함께 제시한다(확정 아님).
      if (g = ground)
        @unresolved << { factor: "AVOIDANCE_INTENT",
                         detail: "회피 목적이 아님이 확인되지 않았습니다. 제77조제3항은 분리 사유가 있어도 수의계약 회피 목적의 분할을 금지합니다." } if @factors["avoidance_intent"] != "no"
        return Result.new(
          state: "LEGITIMATE_SEPARATION_POSSIBLE",
          headline: "#{g['label']}에 해당한다면 분리 발주가 가능합니다. " \
                    "이 판정은 **요건 해당 가능성**이지 적법 확정이 아닙니다 — 해당 여부와 " \
                    "수의계약 회피 목적이 아닌지(제77조제3항)는 담당자가 별도로 확인해야 합니다.",
          track: "CONSTRUCTION", matched_rule: { rule_id: g["ground_id"], source_locator: g["source_locator"] },
          legal_basis: basis + [ rules.citation(g["authority_source"], g["source_locator"], quote: g["label"]) ],
          aggregation: nil, lawful_separation_grounds: lawful_grounds, duties: duties(cfg, ground: g),
          unresolved_factors: @unresolved,
          next_actions: [ "분리 사유의 객관적 근거(설계서·공종 구분·관계 법령)를 계약서류에 남기세요." ] + reporting_action(g),
          input: input_snapshot, review_axes: review_axes
        )
      end

      # ③ 금지 요건 자체의 충족 여부로 판정한다.
      single = @factors["single_project"]
      fixed  = @factors["scope_fixed"]

      if prohibited_shape
        Result.new(
          state: "HIGH_SPLIT_RISK",
          headline: "동일 구조물·단일공사로서 전체 사업내용이 확정된 공사입니다. 시기적·공사량 분할은 제77조제1항이 금지합니다.",
          track: "CONSTRUCTION", matched_rule: { rule_id: "D77-1", source_locator: prohib["source_locator"] },
          legal_basis: basis, aggregation: nil,
          lawful_separation_grounds: lawful_grounds, duties: duties(cfg),
          unresolved_factors: @unresolved,
          next_actions: [ "제77조제1항 각 호의 예외에 해당하는지 먼저 확인하고, 해당하지 않으면 통합 발주하세요." ],
          input: input_snapshot, review_axes: review_axes
        )
      else
        insufficient(unknown_factors(CONSTRUCTION_FACTORS), track: "CONSTRUCTION", basis: basis, cfg: cfg)
      end
    end

    # ── 물품·용역 트랙 (§7제2호) ────────────────────────────────
    def evaluate_goods_service
      cfg = rules.split_procurement["goods_service"]
      basis = [ rules.citation(cfg["authority_source"], cfg["source_locator"], quote: cfg["quote"]) ]
      months = cfg["aggregation_window_months"]

      same   = @factors["same_purpose"]
      window = @factors["within_window"]

      agg = aggregation_view(months)

      # §7제2호 나목의 "직후 12개월"은 미래 구간이다. 지금 입력한 계약만으로 산정한 합산액은
      # 확정치가 아니다 — 확정처럼 보이면 남은 연간 소요를 빼먹은 채 한도 안이라고 판단하게 된다.
      if agg
        @unresolved << {
          factor: "FUTURE_WINDOW",
          detail: "제7조제2호는 직전 12개월뿐 아니라 해당 회계연도·직후 12개월도 산정 기준으로 둡니다. " \
                  "아직 체결하지 않은 같은 목적의 계약이 남아 있으면 합산액은 더 커집니다."
        }
      end

      if same == "no"
        return Result.new(
          state: "LOW_RISK",
          headline: "동일·유사한 조달 요구가 아니라면 제7조제2호의 합산 대상이 아닙니다. " \
                    "다만 이 판정은 '분할해도 된다'는 뜻이 아니라 '합산 산정 대상이 아니다'라는 뜻입니다.",
          track: "GOODS_SERVICE", matched_rule: { rule_id: "D7-2", source_locator: cfg["source_locator"] },
          legal_basis: basis, aggregation: agg, lawful_separation_grounds: [],
          duties: [], unresolved_factors: @unresolved + [ { factor: "SELF_REPORTED",
            detail: "동일·유사 여부는 입력값을 그대로 받아들였습니다. 감사에서는 목적·규격·예산과목으로 다시 판단합니다." } ],
          next_actions: [ "별개 수요임을 보여주는 근거(다른 사업·다른 목적)를 남기세요." ],
          input: input_snapshot, review_axes: review_axes
        )
      end

      if same == "unknown" || window == "unknown"
        return insufficient(unknown_factors(GOODS_SERVICE_FACTORS), track: "GOODS_SERVICE", basis: basis, agg: agg)
      end

      if same == "yes" && window == "yes"
        state = agg && agg[:exceeds_single_quote_threshold] ? "HIGH_SPLIT_RISK" : "REVIEW_NEEDED"
        head =
          if state == "HIGH_SPLIT_RISK"
            "동일·유사한 조달 요구이므로 제7조제2호에 따라 추정가격을 합산해 산정합니다. 합산액이 1인 견적 수의계약 기준(2천만원)을 넘습니다."
          else
            "동일·유사한 조달 요구이므로 제7조제2호에 따라 추정가격을 합산해 산정해야 합니다."
          end
        return Result.new(
          state: state, headline: head, track: "GOODS_SERVICE",
          matched_rule: { rule_id: "D7-2", source_locator: cfg["source_locator"] },
          legal_basis: basis, aggregation: agg, lawful_separation_grounds: [], duties: [],
          unresolved_factors: @unresolved,
          next_actions: [
            "합산한 추정가격으로 계약방식을 다시 판단하세요.",
            "연간 소요를 미리 파악해 단가계약·통합 발주를 검토하세요."
          ],
          input: input_snapshot, review_axes: review_axes
        )
      end

      Result.new(
        state: "REVIEW_NEEDED",
        headline: "동일·유사한 조달 요구이지만 합산 대상 기간(#{months}개월/회계연도) 밖으로 입력되었습니다. 기간 산정을 다시 확인하세요.",
        track: "GOODS_SERVICE", matched_rule: { rule_id: "D7-2", source_locator: cfg["source_locator"] },
        legal_basis: basis, aggregation: agg, lawful_separation_grounds: [], duties: [],
        unresolved_factors: @unresolved,
        next_actions: [ "제7조제2호는 직전 12개월·해당 회계연도·직후 12개월을 기준으로 합니다. 어느 기준을 쓰는지 명시하세요." ],
        input: input_snapshot, review_axes: review_axes
      )
    end

    # 합산 금액은 보여주되, 임계 판정은 §30①2호 본문(2천만원)이라는 조문값으로만 한다.
    def aggregation_view(months)
      return nil if @current.nil? && @priors.empty?

      total = (@current || 0) + @priors.sum
      base = rules.quotation_rules["single_quote_exceptions"].find { |e| e["rule_id"] == "D30-1-2-본문" }
      { current: @current, prior_total: @priors.sum, total: total,
        window_months: months,
        single_quote_threshold: base["max_amount"],
        threshold_locator: base["source_locator"],
        exceeds_single_quote_threshold: total > base["max_amount"] }
    end

    def not_prohibited(cfg, basis)
      Result.new(
        state: "LOW_RISK",
        headline: "제77조제1항의 금지 요건(동일 구조물·단일공사 + 전체 사업내용 확정)을 충족하지 않는 것으로 입력되었습니다. 예외 사유를 따로 주장할 필요가 없습니다.",
        track: "CONSTRUCTION",
        matched_rule: { rule_id: "D77-1", source_locator: cfg.dig("prohibition", "source_locator") },
        legal_basis: basis, aggregation: nil,
        lawful_separation_grounds: lawful_grounds, duties: duties(cfg),
        unresolved_factors: @unresolved + [ { factor: "SELF_REPORTED",
          detail: "이 판정은 입력한 사실관계를 그대로 받아들인 결과입니다. 사실관계가 다르면 결론도 달라집니다." } ],
        next_actions: [ "별개 사업으로 본 객관적 근거를 계약서류에 남기세요." ],
        input: input_snapshot, review_axes: review_axes
      )
    end

    def lawful_grounds = rules.split_procurement.dig("construction", "lawful_separation_grounds")

    def duties(cfg, ground: nil)
      out = [ { kind: "PLANNING", source_locator: cfg.dig("planning_duty", "source_locator"),
                text: cfg.dig("planning_duty", "quote") } ]
      if ground.nil? || ground["reporting_duty"]
        out << { kind: "REPORTING", source_locator: cfg.dig("reporting_duty", "source_locator"),
                 text: cfg.dig("reporting_duty", "quote") }
      end
      out
    end

    def reporting_action(ground)
      return [] unless ground["reporting_duty"]
      [ "제77조제1항제2호에 따른 분할계약은 상급기관 보고 의무가 있습니다 (제77조제4항)." ]
    end

    def unknown_factors(map)
      map.filter_map do |key, locator|
        next if @factors[key.to_s] && @factors[key.to_s] != "unknown"
        { factor: key.to_s.upcase, detail: "#{locator} 요건 판단에 필요한 사실이 확인되지 않았습니다." }
      end
    end

    def insufficient(factors, track: nil, basis: [], agg: nil, cfg: nil)
      Result.new(
        state: "INSUFFICIENT_INFORMATION",
        headline: "지금 입력만으로는 분할발주 여부를 판단할 수 없습니다.",
        track: track, matched_rule: nil, legal_basis: basis, aggregation: agg,
        lawful_separation_grounds: cfg ? lawful_grounds : [],
        duties: cfg ? duties(cfg) : [],
        unresolved_factors: factors,
        next_actions: factors.map { |f| f[:detail] },
        input: input_snapshot, review_axes: review_axes
      )
    end

    def input_snapshot
      { contract_type: @type, factors: @factors, separation_ground: @ground,
        current_amount: @current, prior_amounts: @priors }
    end

    # §5 검토축 — 계약유형별로 근거가 있는 축과 없는 축을 갈라서 낸다.
    # 근거 없는 축(`basis: NONE`)은 판정하지 않고 항상 REVIEW_REQUIRED 로 남긴다.
    def review_axes
      list = rules.split_procurement.dig("review_axes", family) || []
      list.map do |ax|
        answer =
          if ax["basis"] == "NONE" then "REVIEW_REQUIRED"
          elsif ax["factor"] then @factors[ax["factor"]].to_s.upcase
          elsif ax["ground"] then (@ground == ax["ground"] ? "CLAIMED" : "NOT_CLAIMED")
          else "REVIEW_REQUIRED"
          end
        out = { axis: ax["axis"], label: ax["label"], answer: answer,
                decides: ax.key?("factor") }
        if ax["basis"] == "NONE"
          out[:legal_basis] = nil
          out[:review_reason] = ax["review_reason"]
        else
          out[:legal_basis] = rules.citation(ax["authority_source"], ax["source_locator"])
        end
        out[:note] = ax["note"] if ax["note"]
        out
      end
    end
  end
end
