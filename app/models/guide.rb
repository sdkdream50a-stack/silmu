# Created: 2026-02-18 00:35
class Guide < ApplicationRecord
  # Sector enum (0: common 공통, 1: local_gov 지자체, 2: edu 교육행정)
  enum :sector, { common: 0, local_gov: 1, edu: 2 }, default: :common
  # "common" 또는 blank 전달 시 전체 반환 (common은 모든 sector에 공유되므로)
  scope :for_sector, ->(s) { where(sector: [:common, s]) if s.present? && s != "common" }

  # topic_slug 기반 교차 연결
  belongs_to :topic, foreign_key: :topic_slug, primary_key: :slug, optional: true

  scope :published, -> { where(published: true) }
  scope :ordered,   -> { order(:sort_order) }

  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  after_commit :expire_cache
  after_commit :notify_indexnow, if: -> { saved_change_to_published? && published? }

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

  # update_counters는 updated_at을 갱신하지 않으므로 캐시 타임스탬프 무효화 불요
  # popular 캐시는 1시간 TTL로 자연 만료시킴 (매 조회마다 삭제 → 불필요한 DB 쿼리 유발 방지)
  def increment_view!
    self.class.update_counters(id, view_count: 1)
  end

  private

  def notify_indexnow
    SitemapPingJob.perform_later(["https://#{SitemapPingJob::HOST}/guides/#{slug}"])
  end

  def expire_cache
    Rails.cache.delete("guides/all/v2")
    Rails.cache.delete("guides/popular")
    Rails.cache.delete("stats/guide_count")
    Rails.cache.delete("guides/related/#{slug}")
    Rails.cache.delete("guide_topic/#{slug}")
    # topic_slug 또는 external_link가 topic URL인 경우 해당 topic 캐시 무효화
    t_slug = topic_slug.presence || (external_link&.start_with?("/topics/") ? external_link.delete_prefix("/topics/") : nil)
    Rails.cache.delete("topic_guide/#{t_slug}") if t_slug.present?
    Rails.cache.increment("home/curated_version") if saved_change_to_sector? || saved_change_to_topic_slug?
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
