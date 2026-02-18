# Created: 2026-02-18 00:35
class Guide < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :ordered,   -> { order(:sort_order) }

  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  # guide_path(guide) → /guides/purchase-and-inspection
  def to_param
    slug
  end

  # sections JSONB를 HashWithIndifferentAccess로 반환 (기존 뷰의 심볼 키 호환)
  def sections
    raw = self[:sections]
    return nil if raw.blank?
    deep_indifferent(raw)
  end

  def has_full_content?
    self[:sections].present?
  end

  def increment_view!
    self.class.update_counters(id, view_count: 1)
  end

  private

  def generate_slug
    self.slug = title.parameterize.presence || "guide-#{SecureRandom.hex(4)}"
  end

  def deep_indifferent(obj)
    case obj
    when Hash
      obj.with_indifferent_access.transform_values { |v| deep_indifferent(v) }
    when Array
      obj.map { |v| deep_indifferent(v) }
    else
      obj
    end
  end
end
