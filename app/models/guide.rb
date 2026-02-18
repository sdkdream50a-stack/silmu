# Created: 2026-02-18 00:35
class Guide < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :ordered,   -> { order(:sort_order) }

  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  after_commit :expire_cache

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
    Rails.cache.delete("guides/popular")
  end

  private

  def expire_cache
    Rails.cache.delete("guides/all")
    Rails.cache.delete("guides/popular")
    Rails.cache.delete("stats/guide_count")
    Rails.cache.delete("guides/related/#{slug}")
    # external_link가 topic URL인 경우 해당 topic의 캐시도 무효화
    if external_link&.start_with?("/topics/")
      topic_slug = external_link.delete_prefix("/topics/")
      Rails.cache.delete("topic_guide/#{topic_slug}")
    end
  end

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
