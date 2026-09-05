# frozen_string_literal: true

# P1-3 / §12·§13 — 공개 출처 렌더링의 단일 경계.
#
# Guide / Topic / AuditCase / Tool 이 각자 출처를 그리지 않는다.
# 공개 화면에 나가는 모든 권위 정보는 **반드시 이 presenter 를 통과**하며,
# 여기서 InternalMetadataFilter 가 내부 엔지니어링 문자열을 차단한다.
#
# 이 클래스가 없으면 `source: @audit_case.verification_source` 처럼
# DB 문자열이 뷰로 직결되어 P0 의 누출(커밋 해시·batch·lawId)이 재발한다.
class AuthorityPresenter
  attr_reader :record

  def initialize(record)
    @record = record
  end

  # ── 검증: 무엇을 검증했는가 ────────────────────────────────
  def verification_label = record.try(:verification_label)
  def verification_scope_text = record.try(:verification_scope_text)
  def verification_tone = record.try(:verification_tone) || :muted
  def verification_status = record.try(:effective_verification_status)

  def verified_on
    record.try(:effective_verified_at)
  end

  def show_verification? = verified_on.present? || verification_status.present?

  # ── 신선도 ────────────────────────────────────────────────
  def freshness_status = record.try(:freshness_status) || "UNKNOWN"
  def freshness_label  = record.try(:freshness_label)
  def stale? = %w[REVIEW_DUE STALE_SUSPECTED SOURCE_UNAVAILABLE].include?(freshness_status)

  # §31 — 법령이 바뀌었는데 검토가 끝나지 않았다면 사용자에게 알린다.
  def change_pending? = %w[CHANGE_DETECTED REVIEW_REQUIRED].include?(freshness_status)
  def freshness_attention? = record.try(:freshness_attention?) || false

  # 검토 중인 개정의 시행일 (있으면)
  def pending_change_effective_on
    id = record.try(:last_change_event_id)
    return nil if id.blank?

    AuthorityChangeEvent.find_by(id: id)&.effective_at
  end

  def review_due_on
    record.try(:review_due_at) || record.try(:derived_review_due_at)
  end

  def effective_on = record.try(:effective_at)

  # ── 출처: 공개 가능한 것만 ────────────────────────────────
  # 내부 문자열은 여기서 걸러진다. 통과하지 못하면 nil (표시하지 않는다).
  def public_source_label
    explicit = [ source_agency, source_title, source_year ].compact_blank.join(" · ").presence
    return InternalMetadataFilter.public_only(explicit) if explicit

    # 신규 컬럼이 아직 비어 있는 행: 기존 자유 문자열을 쓰되 필터를 통과해야만 한다.
    InternalMetadataFilter.public_only(record.try(:verification_source))
  end

  def source_agency = InternalMetadataFilter.public_only(record.try(:public_source_agency) || record.try(:source_agency))
  def source_title  = InternalMetadataFilter.public_only(record.try(:public_source_title) || record.try(:source_title))
  def source_year   = record.try(:public_source_year) || record.try(:source_year)
  def source_page   = record.try(:public_source_page) || record.try(:source_page)
  def source_url    = record.try(:public_source_url) || record.try(:source_url)
  def source_reference = record.try(:public_source_reference) || record.try(:source_reference)

  def show_source? = public_source_label.present? || source_url.present?

  # ── provenance (감사사례) ─────────────────────────────────
  def provenance_label = record.try(:provenance_label)
  def provenance_note  = record.try(:provenance_note)
  def provenance_tone  = record.try(:provenance_tone)
  def provenance_icon  = record.try(:provenance_icon)
  def reconstructed?   = record.try(:reconstructed_case?) || false

  # §10 원문 미확인 시 승격 금지 — 화면에서도 강등해 표현한다.
  def document_backed? = record.try(:document_backed?) || false

  def show_provenance? = record.respond_to?(:effective_source_type)

  # ── 법령 근거 ─────────────────────────────────────────────
  # 텍스트로만 있던 조문을 검증 가능한 링크로 승격한다(해석 가능한 것만).
  def legal_references
    raw = record.try(:legal_basis)
    return [] if raw.blank?

    LegalReferenceResolver.resolve(raw)
  end

  def linkable_legal_references = legal_references.select(&:resolved?)
  def show_legal_references? = legal_references.any?

  # ── 적용 기관 ─────────────────────────────────────────────
  def show_agency_scope? = record.try(:show_agency_scope?) || false
  def agency_labels = record.try(:target_agency_labels) || []
  def jurisdiction_label = record.try(:jurisdiction_label)
end
