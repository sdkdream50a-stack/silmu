# frozen_string_literal: true

# P2 (2026-09-20 · CONNECTED_WORKFLOW) — 업무 단계 ↔ 기존 자산 결속.
#
# `/guides/contract-flow` 척추(물품·용역·공사 × 8단계)의 각 단계에 «지금 쓸 도구·서식·참고» 를
# 붙인다. 데이터 정본은 `config/workflow_bindings.yml`. 이 클래스는 **읽고 검증만** 한다 —
# 판정 규칙을 새로 만들지 않는다.
#
# fail-closed. `contract_decision_rules.yml` 이 authority_source 없으면 로딩을 거부하듯,
# 여기서도 규율을 어긴 등록부는 «조용히 일부만» 싣지 않고 통째로 거부한다. 결속 하나가
# 조용히 빠지면 화면이 «이 단계엔 도구가 없다» 고 거짓말하기 때문이다.
class WorkflowBindings
  class InvalidRegistry < StandardError; end

  PATH = Rails.root.join("config", "workflow_bindings.yml")

  # 척추가 소유한 단계 id. 여기서 새로 만들지 않는다 — 척추와 어긋나면 그게 결함이다.
  CATEGORIES = %w[goods service construction].freeze
  STEPS_PER_CATEGORY = 8
  STAGE_IDS = CATEGORIES.flat_map { |c| (1..STEPS_PER_CATEGORY).map { |n| "#{c}-#{n}" } }.freeze

  # 「눌렀을 때 업무가 앞으로 나아가는」 묶음과 「읽을거리」 묶음을 나눈다(§5 Q2·Q4).
  ACTIONABLE_GROUPS = %w[tools forms review_lab].freeze
  REFERENCE_GROUPS  = %w[topics guides audit_cases].freeze
  GROUPS = (ACTIONABLE_GROUPS + REFERENCE_GROUPS).freeze

  SCHOOL_TIERS = %w[conditional reference].freeze

  class << self
    # 단계 id → { "tools" => [...], ... }. 없으면 {}.
    def stage(stage_id)
      registry.fetch(stage_id, {})
    end

    def all
      registry
    end

    # 척추 JSON 에 실을 형태. 빈 단계는 키 자체를 싣지 않는다 —
    # 화면이 «비어 있음» 과 «결속이 없음» 을 구분할 필요가 없고, 없는 키는 JS 가 그냥 건너뛴다.
    def payload
      registry.reject { |_, groups| groups.empty? }
    end

    # 결속된 모든 경로(중복 제거). 링크 검사가 이것을 훑는다.
    def all_paths
      registry.values.flat_map { |groups| groups.values.flatten }.map { |i| i["path"] }.uniq
    end

    def reset!  # 테스트 전용
      @registry = nil
      @tool_trust = nil
    end

    private

    def registry
      @registry ||= load!
    end

    def load!
      raw = YAML.load_file(PATH)
      stages = raw.is_a?(Hash) ? raw["stages"] : nil
      raise InvalidRegistry, "stages 키가 없다" unless stages.is_a?(Hash)

      stages.each { |stage_id, groups| validate_stage!(stage_id, groups) }
      stages.transform_values { |groups|
        (groups || {}).transform_values { |items| items.map { |item| resolve(item) }.freeze }.freeze
      }.freeze
    end

    # 학교 적용 차이 문구는 **옮겨 적지 않고 등록부에서 읽는다**. tool_trust 가 고쳐지면
    # 화면도 같이 고쳐진다 — 두 곳에서 따로 유지하면 반드시 어긋난다.
    def resolve(item)
      return item.freeze if item["school"].nil?

      item.merge("school_note" => tool_trust_school_differs(item["school_note_source"])).freeze
    end

    def validate_stage!(stage_id, groups)
      unless STAGE_IDS.include?(stage_id)
        raise InvalidRegistry, "척추에 없는 단계 id: #{stage_id}"
      end
      return if groups.nil?
      raise InvalidRegistry, "#{stage_id}: 단계는 그룹 해시여야 한다" unless groups.is_a?(Hash)

      seen_paths = []
      groups.each do |group, items|
        unless GROUPS.include?(group)
          raise InvalidRegistry, "#{stage_id}: 알 수 없는 그룹 #{group}"
        end
        raise InvalidRegistry, "#{stage_id}/#{group}: 배열이어야 한다" unless items.is_a?(Array)
        raise InvalidRegistry, "#{stage_id}/#{group}: 비어 있다 — 없으면 그룹 자체를 적지 않는다" if items.empty?

        items.each do |item|
          validate_item!(stage_id, group, item)
          if seen_paths.include?(item["path"])
            raise InvalidRegistry, "#{stage_id}: 같은 경로가 한 단계에 두 번 — #{item['path']}"
          end
          seen_paths << item["path"]
        end
      end
    end

    def validate_item!(stage_id, group, item)
      where = "#{stage_id}/#{group}"
      raise InvalidRegistry, "#{where}: 항목은 해시여야 한다" unless item.is_a?(Hash)

      %w[label path why].each do |key|
        value = item[key]
        raise InvalidRegistry, "#{where}: #{key} 가 비었다" if value.nil? || value.to_s.strip.empty?
      end
      unless item["path"].is_a?(String) && item["path"].start_with?("/")
        raise InvalidRegistry, "#{where}: path 는 절대 경로여야 한다 — #{item['path']}"
      end

      tier = item["school"]
      return if tier.nil?

      unless SCHOOL_TIERS.include?(tier)
        raise InvalidRegistry, "#{where}: school 은 #{SCHOOL_TIERS.join('|')} 만 — #{tier}"
      end
      # §9 — LOCAL_GOV_ONLY 를 «행동» 묶음에 두지 않는다. 학교 사용자가 이 자리를
      # «학교에서 쓰는 것» 으로 읽기 때문에, 표시가 아니라 자리로 막는다(P0 원칙 상속).
      if tier == "reference" && ACTIONABLE_GROUPS.include?(group)
        raise InvalidRegistry, "#{where}: 지자체 기준 자산은 행동 묶음에 결속할 수 없다 — #{item['path']}"
      end
      # school 강등·조건부는 **지어낼 수 없다**. 기존 판정(tool_trust jurisdiction)이 근거다.
      source = item["school_note_source"]
      if source.nil? || tool_trust_school_differs(source).nil?
        raise InvalidRegistry,
              "#{where}: school=#{tier} 인데 근거가 없다 — " \
              "config/tool_trust.yml 의 jurisdiction.school_differs 를 가진 도구 키를 school_note_source 에 적어야 한다"
      end
    end

    def tool_trust_school_differs(tool_key)
      tool_trust.dig("tools", tool_key, "jurisdiction", "school_differs")
    end

    def tool_trust
      @tool_trust ||= YAML.load_file(Rails.root.join("config", "tool_trust.yml"))
    end
  end
end
