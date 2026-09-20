# frozen_string_literal: true

# P1-5 §18·§19 — 도구 신뢰 메타데이터.
#
# P0 실측: 도구 37개 중 면책 문구 7개, 기준 연도 표기 5개, 검증 배지 0개.
# 그런데 계산 결과는 그대로 기안으로 들어간다. 기준값이 낡으면 도구가 감사 지적을 생산한다.
#
# 설계 규칙
#   · 37개를 손으로 고치지 않는다 — 공통 레이어 하나가 모든 도구에 붙는다.
#   · 기준일은 **설정 파일에서 직접 읽는다.** 손으로 적으면 그 값이 또 낡는다.
#   · 근거를 모르는 도구는 근거를 만들지 않는다 — 공통 면책만 표시한다.
class ToolTrust
  CONFIG_PATH = Rails.root.join("config", "tool_trust.yml")

  # 기준값을 소유한 설정 파일 → 화면에 표시할 버전 문자열
  STANDARD_SOURCES = {
    "contract_thresholds" => {
      path: Rails.root.join("config", "contract_thresholds.yml"),
      label: "계약 기준값",
      # 이 파일은 version 키가 없어 헤더 주석에 최종 갱신일이 있다.
      version_pattern: /마지막 업데이트:\s*(\d{4}-\d{2}-\d{2})/
    },
    "legal_standards" => {
      path: Rails.root.join("config", "legal_standards.yml"),
      label: "법령 기준값",
      version_key: "version"
    }
  }.freeze

  Info = Struct.new(:tool_key, :basis, :standard_label, :standard_version,
                    :legal_references, :disclaimer, :jurisdiction, keyword_init: true) do
    def any_basis? = basis.present? || standard_version.present? || legal_references.any?
  end

  # ── P4 §10 — 관할 전수 census ────────────────────────────────────────────────
  # `jurisdiction` 블록(화면에 렌더되는 고지)과 **다른 축**이다.
  # 고지는 «사용자에게 무엇을 말할 것인가», scope 는 «이 도구가 어느 기관 기준인가» 다.
  # 고지가 없어도 scope 는 있을 수 있고(예: 전국 단일 법령), 그 반대도 있다.
  SCOPES = %w[SCHOOL_DIRECT SCHOOL_WITH_CONDITION LOCAL_GOV_ONLY NATIONAL GENERAL UNKNOWN].freeze
  UNKNOWN_SCOPE = "UNKNOWN"

  Scope = Struct.new(:tool_key, :scope, :reason, keyword_init: true) do
    def known? = scope != UNKNOWN_SCOPE
    def school_usable? = %w[SCHOOL_DIRECT SCHOOL_WITH_CONDITION NATIONAL GENERAL].include?(scope)
  end

  # P0-2 — 적용기관 고지. 「학교회계인가 지방자치단체 기준인가」를 계산 전에 세운다.
  # 기준연도를 모르면 만들지 않는다 — UNVERIFIED 는 화면에서 «미표기» 로 정직하게 나간다.
  Jurisdiction = Struct.new(:applies_to, :agency, :guideline, :standard_year,
                            :school_differs, :school_path, :school_path_label,
                            keyword_init: true) do
    UNVERIFIED = "UNVERIFIED"

    def standard_year_verified? = standard_year.present? && standard_year.to_s != UNVERIFIED
    def school_note? = school_differs.present?
  end

  class << self
    def for(tool_key)
      key = tool_key.to_s.sub(/\Atool:/, "")
      entry = config.dig("tools", key) || {}
      std = STANDARD_SOURCES[entry["standard"]]

      Info.new(
        tool_key: key,
        basis: entry["basis"],
        standard_label: std&.dig(:label),
        standard_version: std ? standard_version(entry["standard"]) : nil,
        legal_references: entry["laws"].present? ? LegalReferenceResolver.resolve(entry["laws"]) : [],
        disclaimer: config.dig("defaults", "disclaimer"),
        jurisdiction: build_jurisdiction(entry["jurisdiction"])
      )
    end

    def build_jurisdiction(raw)
      return nil if raw.blank?

      Jurisdiction.new(**raw.symbolize_keys.slice(*Jurisdiction.members))
    end

    def registered_tool_keys = config.fetch("tools", {}).keys

    # 등록되지 않은 키는 «판정 안 함» 이다 — 조용히 안전한 값으로 떨어지지 않는다.
    def scope_for(tool_key)
      key = tool_key.to_s.sub(/\Atool:/, "")
      raw = jurisdiction_scope[key]
      return Scope.new(tool_key: key, scope: UNKNOWN_SCOPE, reason: "관할 census 에 등록되지 않은 도구") if raw.nil?

      value = raw["scope"].to_s
      value = UNKNOWN_SCOPE unless SCOPES.include?(value)
      Scope.new(tool_key: key, scope: value, reason: raw["reason"])
    end

    def jurisdiction_scope = config.fetch("jurisdiction_scope", {})

    def scope_census = jurisdiction_scope.keys.index_with { |k| scope_for(k) }

    # 설정 파일에서 기준일을 **직접** 읽는다 → 파일이 낡으면 화면이 스스로 낡았다고 말한다.
    def standard_version(standard)
      src = STANDARD_SOURCES[standard.to_s]
      return nil if src.nil?

      @standard_versions ||= {}
      @standard_versions[standard.to_s] ||= begin
        raw = File.read(src[:path])
        if src[:version_key]
          YAML.safe_load(raw, permitted_classes: [ Date ])&.dig(src[:version_key]).to_s.presence
        else
          raw[src[:version_pattern], 1]
        end
      rescue Errno::ENOENT, Psych::SyntaxError => e
        Rails.logger.warn "[ToolTrust] 기준값 파일 읽기 실패 (#{standard}): #{e.message}"
        nil
      end
    end

    def config
      @config ||= YAML.safe_load(File.read(CONFIG_PATH), permitted_classes: [ Date ]) || {}
    rescue Errno::ENOENT, Psych::SyntaxError => e
      Rails.logger.warn "[ToolTrust] tool_trust.yml 읽기 실패: #{e.message}"
      {}
    end

    def reset! = (@config = nil; @standard_versions = nil)
  end
end
