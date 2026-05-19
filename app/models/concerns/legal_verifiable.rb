# 2026-05-19 권위자 P7(법무) + P4(SEO) 권고 #C
# 콘텐츠 법령 정합성 검증 추적 (Topic / Guide / AuditCase 공통)
module LegalVerifiable
  extend ActiveSupport::Concern

  VERIFICATION_METHODS = {
    "mcp_law_api" => "법제처 OPEN API (mcp)",
    "manual"      => "수동 검증",
    "pdf"         => "PDF 원문 대조",
    "expert"      => "전문가 검토"
  }.freeze

  FRESH_DAYS = 180  # 6개월 = "최근 검증"

  included do
    scope :verified_recently, -> { where("last_verified_at > ?", FRESH_DAYS.days.ago) }
    scope :stale_verification, -> { where("last_verified_at <= ? OR last_verified_at IS NULL", FRESH_DAYS.days.ago) }
  end

  def verified?
    last_verified_at.present?
  end

  def verification_fresh?
    verified? && last_verified_at > FRESH_DAYS.days.ago
  end

  def verification_age_days
    return nil unless verified?
    ((Time.current - last_verified_at) / 1.day).to_i
  end

  def verification_method_label
    VERIFICATION_METHODS[verification_method] || verification_method
  end

  # 검증 정보 일괄 설정 (rake task / 시드에서 사용)
  def mark_verified!(method: "mcp_law_api", source: nil, at: Time.current)
    update!(
      last_verified_at: at,
      verification_method: method,
      verification_source: source
    )
  end

  # Topic은 law_verified_at 자동 콜백을 가짐 (콘텐츠 변경 시 자동 갱신).
  # last_verified_at(명시 검증) 우선, 없으면 fallback.
  def effective_verified_at
    last_verified_at.presence || (respond_to?(:law_verified_at) ? law_verified_at : nil)
  end

  def effective_verification_label
    if last_verified_at.present?
      verification_method_label || "법제처 OPEN API (mcp)"
    else
      "silmu 자체 검토 (콘텐츠 변경 자동 갱신)"
    end
  end
end
