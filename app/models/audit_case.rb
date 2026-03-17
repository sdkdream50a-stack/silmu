class AuditCase < ApplicationRecord
  # Sector enum (0: common 공통, 1: local_gov 지자체, 2: edu 교육행정)
  enum :sector, { common: 0, local_gov: 1, edu: 2 }, default: :common
  # "common" 또는 blank 전달 시 전체 반환 (common은 모든 sector에 공유되므로)
  scope :for_sector, ->(s) { where(sector: [:common, s]) if s.present? && s != "common" }

  scope :published, -> { where(published: true) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :by_severity, ->(sev) { where(severity: sev) if sev.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :repeated, -> { where(repeated_issue: true) }

  def self.search_by_query(query, limit: 3)
    return none if query.blank?
    sanitized = sanitize_sql_like(query)
    published
      .where("title ILIKE ? OR issue ILIKE ? OR category ILIKE ?",
             "%#{sanitized}%", "%#{sanitized}%", "%#{sanitized}%")
      .order(view_count: :desc)
      .limit(limit)
  end

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  after_commit :expire_count_cache
  after_commit :notify_indexnow, if: -> { saved_change_to_published? && published? }

  # 카테고리 목록
  CATEGORIES = {
    "수의계약" => "수의계약",
    "입찰" => "입찰",
    "계약체결" => "계약체결",
    "계약이행" => "계약이행",
    "대금지급" => "대금지급",
    "하도급" => "하도급",
    "예산" => "예산",
    "회계" => "회계",
    "검수/검사" => "검수/검사",
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

  def notify_indexnow
    SitemapPingJob.perform_later(["https://#{SitemapPingJob::HOST}/audit-cases/#{slug}"])
  end

  def expire_count_cache
    Rails.cache.delete("stats/audit_case_count")
    Rails.cache.delete("audit_cases/all_published_v2")
    Rails.cache.delete("audit_case_topic/#{slug}")
    Rails.cache.delete("audit_case_related/#{slug}")
    # 뷰 fragment cache 무효화: 내용 변경 시 버전 증가
    if saved_change_to_title? || saved_change_to_issue? || saved_change_to_published? || saved_change_to_sector? || saved_change_to_severity? || saved_change_to_repeated_issue?
      Rails.cache.increment("audit_cases/fragment_version")
      Rails.cache.increment("home/curated_version")
    end
  end

  def generate_slug
    base = title.parameterize.presence || "audit-case-#{SecureRandom.hex(4)}"
    self.slug = base
  end
end
