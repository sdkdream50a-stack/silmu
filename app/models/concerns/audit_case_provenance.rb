# frozen_string_literal: true

# P1-1 / §6 Source Type Taxonomy — 감사사례 출처 유형.
#
# P0 감사에서 확인된 것:
#   · `source` jsonb 에 이미 원문 URL·페이지·발행기관이 들어 있는 행이 존재한다(렌더만 안 됐다).
#   · `verification_source` 문자열에는 공개하면 안 되는 내부 로그가 섞여 있다.
# 이 concern 은 **새 사실을 만들지 않고** 이미 있는 데이터를 유형으로 표현한다.
module AuditCaseProvenance
  extend ActiveSupport::Concern

  SOURCE_TYPES = {
    "ACTUAL_AUDIT" => {
      label: "실제 감사결과", icon: "gavel", tone: :green,
      note:  "공공기관이 공개한 감사결과 문서에 근거한 사례입니다."
    },
    "COURT_CASE" => {
      label: "판례·재결", icon: "balance", tone: :purple,
      note:  "법원 판결 또는 행정심판·소청 재결에 근거한 사례입니다."
    },
    "OFFICIAL_INTERPRETATION" => {
      label: "공식 질의·유권해석", icon: "help_center", tone: :blue,
      note:  "소관 부처·법제처 등의 유권해석·질의회신에 근거한 사례입니다."
    },
    "OFFICIAL_GUIDELINE" => {
      label: "공식 지침·편람", icon: "menu_book", tone: :blue,
      note:  "공식 집행기준·편람에 근거한 사례입니다."
    },
    "LAW_OR_REGULATION" => {
      label: "법령 근거", icon: "article", tone: :blue,
      note:  "법령·시행령·시행규칙 조문에 근거한 설명입니다."
    },
    "SILMU_RECONSTRUCTED_CASE" => {
      label: "실무.kr 재구성 사례", icon: "draw", tone: :amber,
      note:  "이 사례는 특정 기관의 실제 감사결과 원문을 그대로 재현한 것이 아니라, " \
             "반복적으로 발생하는 감사 지적 유형을 바탕으로 실무 예방을 위해 재구성한 사례입니다."
    },
    "SILMU_SIMULATED_CASE" => {
      label: "가상 예방 시나리오", icon: "lightbulb", tone: :amber,
      note:  "실제 감사결과가 아닙니다. 감사에서 자주 지적되는 유형을 설명하려고 실무.kr이 만든 가상 시나리오이며, " \
             "기관·인물·일시·금액·처분 내용은 모두 예시입니다. 실제 처분은 사실관계에 따라 달라집니다."
    },
    "SECONDARY_SOURCE" => {
      label: "2차 자료", icon: "description", tone: :gray,
      note:  "해설서·실무자료 등 2차 자료에 근거합니다. 결론은 공식 원문으로 재확인하세요."
    },
    "UNVERIFIED" => {
      label: "출처 추가 검증 필요", icon: "help", tone: :gray,
      note:  "출처를 아직 확정하지 못했습니다. 실제 업무 적용 전 공식 원문을 확인하세요."
    }
  }.freeze

  # 실제 사건으로 오해하면 안 되는 유형
  RECONSTRUCTED_TYPES = %w[SILMU_RECONSTRUCTED_CASE SILMU_SIMULATED_CASE].freeze

  # 검색 결과·AI 인용은 배너 없이 제목·설명만 가져간다 — 실제 사건으로 읽히지 않도록 유형을 앞에 붙인다.
  SEO_PREFIXES = {
    "SILMU_SIMULATED_CASE" => "[가상 예방 시나리오] ",
    "SILMU_RECONSTRUCTED_CASE" => "[재구성 사례] ",
    "UNVERIFIED" => "[출처 미확정] "
  }.freeze
  # 원문 문서가 존재해야 정당한 유형 (§10: 원문 미확인 시 승격 금지)
  DOCUMENT_BACKED_TYPES = %w[ACTUAL_AUDIT COURT_CASE OFFICIAL_INTERPRETATION OFFICIAL_GUIDELINE].freeze

  included do
    scope :by_source_type, ->(t) { where(source_type: t) if t.present? }
    scope :provenance_unclassified, -> { where(source_type: nil) }
    scope :reconstructed, -> { where(is_reconstructed: true) }
  end

  def effective_source_type
    return source_type if source_type.present? && SOURCE_TYPES.key?(source_type)

    "UNVERIFIED"
  end

  def provenance_descriptor = SOURCE_TYPES.fetch(effective_source_type)
  def provenance_label = provenance_descriptor[:label]
  def provenance_note  = provenance_descriptor[:note]
  def provenance_tone  = provenance_descriptor[:tone]
  def provenance_icon  = provenance_descriptor[:icon]

  def seo_type_prefix = SEO_PREFIXES.fetch(effective_source_type, "")

  # 제목 접미어: 원문 근거 유형만 «사례», 나머지는 «유형»
  def seo_title_suffix
    document_backed? ? "감사 지적 사례와 실무 대응 방법" : "감사 지적 유형과 실무 대응 방법"
  end

  def reconstructed_case?
    return true if is_reconstructed
    RECONSTRUCTED_TYPES.include?(effective_source_type)
  end

  # §10: 원문을 확인하지 못했으면 ACTUAL_AUDIT 로 승격하지 않는다.
  # 컬럼이 승격되어 있더라도 원문 URL 이 없으면 화면에서는 강등해 표시한다.
  def document_backed?
    DOCUMENT_BACKED_TYPES.include?(effective_source_type) && public_source_url.present?
  end

  # ── 공개 가능한 출처 정보만 노출 ──────────────────────────
  # 신규 컬럼이 비어 있으면 기존 `source` jsonb 에서 읽는다(무손실 이행 기간 대응).
  def source_hash
    source.is_a?(Hash) ? source : {}
  end

  def public_source_url
    source_url.presence || source_hash["url"].presence
  end

  def public_source_agency
    source_agency.presence || source_hash["publisher"].presence
  end

  def public_source_title
    source_title.presence || source_hash["publication"].presence
  end

  def public_source_year
    source_year || source_hash["year"].presence&.to_i
  end

  def public_source_page
    source_page || source_hash["page"].presence&.to_i
  end

  def public_source_reference
    source_reference.presence || source_hash["post_url"].presence
  end

  # 사용자에게 보여줄 출처 정보가 하나라도 있는가
  def public_source_present?
    public_source_url.present? || public_source_agency.present? || public_source_title.present?
  end
end
