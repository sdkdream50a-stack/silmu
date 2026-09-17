# frozen_string_literal: true

# P1-1 / §25~§27 — 감사사례 provenance 분류기.
#
# ⚠️ Backfill ≠ 공식 원문을 새로 만들어 넣는 것.
#    이 분류기는 **이미 DB 에 있는 사실만** 구조화한다. 외부 조회·추론으로 출처를 창작하지 않는다.
#
# 신뢰도 게이트 (§27):
#    HIGH   → 자동 적용
#    MEDIUM → 검토 큐 (자동 적용 안 함)
#    LOW    → 변경하지 않음
class AuditCaseProvenanceClassifier
  Plan = Struct.new(
    :audit_case, :source_type, :source_agency, :source_title, :source_url,
    :source_year, :source_page, :source_reference, :is_reconstructed,
    :verification_status, :verification_note, :confidence, :reason,
    keyword_init: true
  ) do
    def applicable? = confidence == "HIGH"
    def requires_review? = confidence == "MEDIUM"

    def attributes_to_apply
      {
        source_type: source_type,
        source_agency: source_agency,
        source_title: source_title,
        source_url: source_url,
        source_year: source_year,
        source_page: source_page,
        source_reference: source_reference,
        is_reconstructed: is_reconstructed,
        verification_status: verification_status,
        verification_note: verification_note,
        provenance_confidence: confidence
      }.compact
    end
  end

  # 재구성 사례임을 스스로 밝힌 표현 (운영 데이터 실측 기반, 정확 매칭 지향)
  RECONSTRUCTED_MARKERS = [
    "특정 실사례 아님",
    "silmu 자체 시드",
    "공개 감사패턴 일반화",
    "감사패턴 일반화"
  ].freeze

  RECONSTRUCTED_SOURCE_STRINGS = %w[silmu-2026 silmu_seed].freeze

  # 본문(issue/detail/lesson)이 재구성임을 밝히는 표현
  BODY_RECONSTRUCTED_MARKERS = [ "가상 시나리오" ].freeze

  # 원문 대조로 강등된 사례 표식 — 원문을 다시 확인하기 전에는 ACTUAL 로 되돌리지 않는다.
  TRUST_DOWNGRADE_MARKER = "TRUST_DOWNGRADE_2026_09_17"

  def initialize(audit_case)
    @ac = audit_case
  end

  def self.plan_for(audit_case) = new(audit_case).plan

  def plan
    raw_source = @ac.verification_source
    note = InternalMetadataFilter.internal?(raw_source) ? raw_source : nil

    # 재구성 판정이 원문 문서 존재보다 먼저다(2026-09-17 신뢰 감사).
    # 원문 URL 이 있어도 본문이 «가상 시나리오»라고 스스로 밝히면 원문 발췌 + 재구성 혼합이다 —
    # 종전 순서에서는 이 86건 중 52건이 «실제 감사결과»로 올라갔다. 원문 필드는 참고로 남는다(Plan.compact).
    if reconstructed?
      return Plan.new(
        audit_case: @ac,
        source_type: "SILMU_RECONSTRUCTED_CASE",
        is_reconstructed: true,
        verification_status: legal_reference_verified? ? "LEGAL_REFERENCE_VERIFIED" : "RECONSTRUCTED",
        # 강등 표식을 덮어쓰면 다음 분류에서 다시 ACTUAL 로 올라간다 — 표식이 있으면 그대로 둔다.
        verification_note: @ac.verification_note.to_s.include?(TRUST_DOWNGRADE_MARKER) ? @ac.verification_note : note,
        confidence: "HIGH",
        reason: "콘텐츠가 스스로 재구성 사례임을 명시 (#{reconstructed_evidence})"
      )
    end

    if (doc = document_source)
      # ── 원문 문서가 DB 에 이미 있다 → ACTUAL_AUDIT (§10 충족) ──
      return Plan.new(
        audit_case: @ac,
        source_type: "ACTUAL_AUDIT",
        source_agency: doc["publisher"].presence,
        source_title: doc["publication"].presence,
        source_url: doc["url"].presence,
        source_year: doc["year"].presence&.to_i,
        source_page: doc["page"].presence&.to_i,
        source_reference: doc["post_url"].presence,
        is_reconstructed: false,
        verification_status: "OFFICIAL_SOURCE_VERIFIED",
        verification_note: note,
        confidence: "HIGH",
        reason: "source jsonb 에 발행기관·문서명·원문 URL·페이지가 모두 존재 (외부 조회 없이 확인 가능)"
      )
    end

    if note.present?
      # ── 출처 자리에 내부 로그만 있다 → 출처 미상. 정직하게 UNVERIFIED 로 두고 로그는 이관 ──
      return Plan.new(
        audit_case: @ac,
        source_type: "UNVERIFIED",
        verification_status: legal_reference_verified? ? "LEGAL_REFERENCE_VERIFIED" : "UNVERIFIED",
        verification_note: note,
        confidence: "HIGH",
        reason: "verification_source 가 내부 엔지니어링 메타데이터 — 사례 출처로 볼 수 없음. " \
                "문자열은 verification_note 로 이관하고 공개 렌더에서 제외"
      )
    end

    if raw_source.blank?
      return Plan.new(
        audit_case: @ac,
        source_type: "UNVERIFIED",
        verification_status: legal_reference_verified? ? "LEGAL_REFERENCE_VERIFIED" : "UNVERIFIED",
        confidence: "HIGH",
        reason: "출처 정보 없음 — UNVERIFIED 로 명시 (기존에도 실질적 미검증 상태)"
      )
    end

    # 실명 기관을 언급하지만 원문 URL 이 없다 → 승격 금지, 사람 검토 (§10)
    Plan.new(
      audit_case: @ac,
      source_type: nil,
      verification_status: nil,
      confidence: "MEDIUM",
      reason: "출처 문자열은 있으나 원문 URL·페이지가 없어 ACTUAL_AUDIT 로 승격 불가 — 검토 큐"
    )
  end

  private

  # source jsonb 가 완전한 문서 출처인가
  def document_source
    h = @ac.source
    return nil unless h.is_a?(Hash)
    return nil if h["url"].blank? || h["publisher"].blank?

    h
  end

  def reconstructed?
    reconstructed_evidence.present?
  end

  def reconstructed_evidence
    return @evidence if defined?(@evidence)

    @evidence =
      if @ac.source.is_a?(String) && RECONSTRUCTED_SOURCE_STRINGS.include?(@ac.source)
        "source=#{@ac.source}"
      elsif (m = RECONSTRUCTED_MARKERS.find { |k| @ac.verification_source.to_s.include?(k) })
        "verification_source 에 '#{m}'"
      elsif @ac.verification_note.to_s.include?(TRUST_DOWNGRADE_MARKER)
        "신뢰 강등 기록(#{TRUST_DOWNGRADE_MARKER}) — 원문 재확인 전 승격 금지"
      elsif BODY_RECONSTRUCTED_MARKERS.any? { |k| [ @ac.issue, @ac.detail, @ac.lesson ].join(" ").include?(k) }
        "본문이 스스로 가상 시나리오임을 밝힘"
      end
  end

  # legal_basis 에서 HIGH confidence 로 해석되는 법령 참조가 하나라도 있는가
  def legal_reference_verified?
    return false if @ac.legal_basis.blank?

    LegalReferenceResolver.resolve(@ac.legal_basis).any? { |r| r.confidence == "HIGH" }
  end
end
