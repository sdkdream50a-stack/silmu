# frozen_string_literal: true

# P1 §23·§24 — 적용 기관 범위.
#
# P0 실측: 콘텐츠 549건 중 352건(64%)이 "어느 기관에 적용되는지" 판별 불가였고,
# 국가·지방 규정을 함께 인용하면서 적용 대상을 밝히지 않은 항목이 85건이었다.
#
# 원칙: **부정확한 metadata 는 빈 metadata 보다 위험하다.**
# 근거 없이 "전국 공통"으로 판정하지 않으며, 애매하면 비워 둔다.
module AgencyScope
  extend ActiveSupport::Concern

  AGENCY_TYPES = {
    "CENTRAL_GOVERNMENT"       => "중앙행정기관",
    "LOCAL_GOVERNMENT"         => "지방자치단체",
    "EDUCATION_OFFICE"         => "시·도교육청",
    "EDUCATION_SUPPORT_OFFICE" => "교육지원청",
    "PUBLIC_SCHOOL"            => "공립학교",
    "PRIVATE_SCHOOL"           => "사립학교",
    "PUBLIC_INSTITUTION"       => "공공기관"
  }.freeze

  JURISDICTIONS = {
    "NATIONAL"    => "국가",
    "LOCAL"       => "지방",
    "EDUCATION"   => "교육행정",
    "BOTH"        => "국가·지방 공통",
    "INSTITUTION" => "공공기관"
  }.freeze

  CONFIDENCE_LEVELS = %w[HIGH MEDIUM LOW].freeze

  included do
    scope :with_jurisdiction, ->(j) { where(jurisdiction: j) if j.present? }
    scope :agency_unresolved, -> { where("target_agency = '{}' OR target_agency IS NULL") }
  end

  def agency_scope_resolved?
    target_agency.present? && agency_scope_confidence == "HIGH"
  end

  def target_agency_labels
    Array(target_agency).filter_map { |code| AGENCY_TYPES[code] }
  end

  def jurisdiction_label = JURISDICTIONS[jurisdiction]

  # 화면에 "적용 대상"을 표시할 수 있는가.
  # HIGH confidence 가 아니면 표시하지 않는다 — 잘못된 적용 범위는 오답을 만든다.
  def show_agency_scope?
    agency_scope_resolved? && target_agency_labels.any?
  end
end
