# frozen_string_literal: true

# P1-1 / P1-6 — 권위 메타데이터 (Topic / Guide / AuditCase 공통)
#
# 이 concern 이 푸는 문제(P0 감사 TR-02):
#   기존에는 `last_verified_at` 이 있으면 화면에 "5단계 정합성 검증 완료" 하나만 떴다.
#   그 배지는 *법령 근거*를 검증했다는 뜻인데 사용자는 *사례 사실관계*가 검증된 것으로 읽었다.
#   실제로 배지가 붙은 감사사례 246건 중 110건은 스스로 "특정 실사례 아님"이라 밝힌 재구성 사례였다.
#   (/about 에 "5단계 정합성 검증" 정의가 있으나 그것은 **법령 콘텐츠** 검증 절차이며,
#    배지에서 도달할 수도 없었다 — 범위를 화면에서 직접 말해야 한다.)
#
# 따라서 "검증했다"를 **무엇을 검증했는지**로 쪼갠다. 단일 boolean 을 쓰지 않는다.
module AuthorityMetadata
  extend ActiveSupport::Concern

  # 검증 범위 — 좁은 것에서 넓은 것 순. 상위가 하위를 함의하지 않는다(별개 사실).
  VERIFICATION_STATUSES = {
    "OFFICIAL_SOURCE_VERIFIED"     => {
      label: "공식 원문 확인",
      scope: "공식 발행 문서 원문까지 확인했습니다.",
      tone:  :strong
    },
    "LEGAL_REFERENCE_VERIFIED"     => {
      label: "법령 근거 검증",
      scope: "인용한 법령·조문을 국가법령정보센터 원문과 대조했습니다. 사례의 사실관계 검증과는 다릅니다.",
      tone:  :normal
    },
    "CONTENT_CONSISTENCY_VERIFIED" => {
      label: "내용 정합성 검토",
      scope: "실무.kr 내부 기준으로 내용 일관성을 검토했습니다. 공식 원문 대조는 포함되지 않습니다.",
      tone:  :weak
    },
    "RECONSTRUCTED"                => {
      label: "재구성 콘텐츠",
      scope: "실제 특정 사건의 원문이 아니라 반복 발생 유형을 재구성한 것입니다.",
      tone:  :info
    },
    "UNVERIFIED"                   => {
      label: "검증 정보 없음",
      scope: "아직 검증 기록이 없습니다. 반드시 공식 원문을 확인하세요.",
      tone:  :muted
    }
  }.freeze

  FRESHNESS_STATUSES = %w[CURRENT REVIEW_DUE STALE_SUSPECTED UNKNOWN].freeze

  # 재검증 주기. LegalVerifiable::FRESH_DAYS(180) 와 정합을 맞춘다.
  REVIEW_INTERVAL_DAYS = 180
  # 기한 경과 후 이만큼 더 지나면 STALE_SUSPECTED
  STALE_GRACE_DAYS = 90

  included do
    scope :with_verification_status, ->(s) { where(verification_status: s) if s.present? }
    scope :review_overdue, -> { where(review_due_at: ...Date.current) }
  end

  # ── 검증 범위 ──────────────────────────────────────────────
  # verification_status 가 아직 backfill 되지 않은 행도 안전하게 동작해야 한다.
  # 명시값이 없으면 기존 신호(last_verified_at)에서 **가장 보수적인** 값을 유도한다.
  def effective_verification_status
    return verification_status if verification_status.present? &&
                                  VERIFICATION_STATUSES.key?(verification_status)
    return "UNVERIFIED" unless respond_to?(:effective_verified_at) && effective_verified_at.present?

    "CONTENT_CONSISTENCY_VERIFIED"
  end

  def verification_descriptor
    VERIFICATION_STATUSES.fetch(effective_verification_status)
  end

  def verification_label = verification_descriptor[:label]
  def verification_scope_text = verification_descriptor[:scope]
  def verification_tone = verification_descriptor[:tone]

  # ── 신선도 ────────────────────────────────────────────────
  # P1.5: Freshness Engine 이 **관측한** 상태(freshness_state)가 있으면 그것이 우선한다.
  #       엔진이 아직 보지 않은 콘텐츠는 P1 의 유도값(재검증 기한 기반)으로 답한다.
  def freshness_status
    return freshness_state if respond_to?(:freshness_state) &&
                              freshness_state.present? &&
                              ContentFreshnessUpdater::STATES.include?(freshness_state)

    derived_freshness_status
  end

  def derived_freshness_status
    due = review_due_at || derived_review_due_at
    return "UNKNOWN" if due.blank?
    return "CURRENT" if due >= Date.current
    return "REVIEW_DUE" if due >= Date.current - STALE_GRACE_DAYS

    "STALE_SUSPECTED"
  end

  FRESHNESS_LABELS = {
    "CURRENT"               => "현재 기준 확인",
    "REVIEW_DUE"            => "재검증 예정일 경과",
    "CHANGE_DETECTED"       => "최신 개정사항 확인 중",
    "REVIEW_REQUIRED"       => "최신 개정사항 검토 중",
    "VERIFIED_AFTER_CHANGE" => "개정 반영 확인 완료",
    "STALE_SUSPECTED"       => "재검증 필요",
    "SOURCE_UNAVAILABLE"    => "공식 출처 확인 불가",
    "UNKNOWN"               => "확인 주기 미설정"
  }.freeze

  def freshness_label = FRESHNESS_LABELS[freshness_status] || "확인 주기 미설정"

  # §31 — 중요 업무 콘텐츠에서 이 상태를 숨기지 않는다.
  def freshness_attention? = %w[CHANGE_DETECTED REVIEW_REQUIRED SOURCE_UNAVAILABLE].include?(freshness_status)

  # 이 콘텐츠에 걸린 열린 검토 태스크
  def open_authority_review_tasks
    return AuthorityReviewTask.none unless persisted?

    AuthorityReviewTask.open.where(affected_type: self.class.name, affected_id: id)
  end

  # review_due_at 이 비어 있어도 화면이 스스로 낡음을 말할 수 있게 유도값을 만든다.
  # (P0 TR-05: 검증이 3개월 멈췄는데도 화면은 계속 "검증 완료"라고 말했다)
  def derived_review_due_at
    base = respond_to?(:effective_verified_at) ? effective_verified_at : nil
    return nil if base.blank?

    base.to_date + REVIEW_INTERVAL_DAYS
  end

  # 공개 화면에 표시할 기준일(있는 것만). 없으면 nil 을 그대로 반환한다.
  def authority_effective_on = effective_at
end
