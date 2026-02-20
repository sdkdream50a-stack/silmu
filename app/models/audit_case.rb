class AuditCase < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :by_severity, ->(sev) { where(severity: sev) if sev.present? }
  scope :recent, -> { order(created_at: :desc) }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  after_commit :expire_count_cache

  # 카테고리 목록
  CATEGORIES = {
    "수의계약" => "수의계약",
    "입찰" => "입찰",
    "계약체결" => "계약체결",
    "계약이행" => "계약이행",
    "대금지급" => "대금지급",
    "하도급" => "하도급",
    "기타" => "기타"
  }.freeze

  SEVERITIES = {
    "경미" => "경미",
    "보통" => "보통",
    "중대" => "중대"
  }.freeze

  def checkpoint_list
    return [] if checkpoints.blank?
    JSON.parse(checkpoints) rescue []
  end

  def related_topic
    return nil if topic_slug.blank?
    Topic.published.find_by(slug: topic_slug)
  end

  def severity_color
    case severity
    when "경미" then "amber"
    when "보통" then "orange"
    when "중대" then "red"
    else "gray"
    end
  end

  def increment_view!
    self.class.update_counters(id, view_count: 1)
  end

  private

  def expire_count_cache
    Rails.cache.delete("stats/audit_case_count")
    Rails.cache.delete("audit_cases/all_published")
    Rails.cache.delete("audit_case_topic/#{slug}")
    Rails.cache.delete("audit_case_related/#{slug}")
  end

  def generate_slug
    base = title.parameterize.presence || "audit-case-#{SecureRandom.hex(4)}"
    self.slug = base
  end
end
