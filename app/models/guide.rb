# Created: 2026-02-18 00:35
class Guide < ApplicationRecord
  include PgSearch::Model

  # 검색 설정
  pg_search_scope :search_by_keyword,
    against: [:title],
    using: {
      tsearch: { prefix: true, dictionary: "simple" },
      trigram: { threshold: 0.1 }
    }

  # Sector enum (0: common 공통, 1: local_gov 지자체, 2: edu 교육행정)
  enum :sector, { common: 0, local_gov: 1, edu: 2 }, default: :common
  # "common" 또는 blank 전달 시 전체 반환 (common은 모든 sector에 공유되므로)
  scope :for_sector, ->(s) { where(sector: [:common, s]) if s.present? && s != "common" }

  # topic_slug 기반 교차 연결
  belongs_to :topic, foreign_key: :topic_slug, primary_key: :slug, optional: true

  scope :published,     -> { where(published: true) }
  scope :ordered,       -> { order(:sort_order) }
  scope :series_guides, -> { where.not(series: nil) }
  scope :for_series,    ->(s) { where(series: s).order(:series_order) }

  # 한글 series 식별자 ↔ 영문 URL slug 매핑
  SERIES_SLUG_MAP = {
    "지방보조금_완전정복"  => "subsidy-complete",
    "수의계약_완전정복"    => "contract-complete",
    "예산편성_완전정복"    => "budget-planning-complete",
    "예산집행_완전정복"    => "budget-execution-complete",
    "출장여비_완전정복"    => "travel-complete",
    "인사복무_완전정복"    => "hr-complete",
    "공사계약_완전정복"    => "construction-complete",
    "입찰_완전정복"        => "bid-complete"
  }.freeze
  SERIES_SLUG_MAP_INVERSE = SERIES_SLUG_MAP.invert.freeze

  def self.series_slug(korean_name)
    SERIES_SLUG_MAP[korean_name]
  end

  def self.series_by_slug(slug)
    SERIES_SLUG_MAP_INVERSE[slug]
  end

  validates :title,        presence: true
  validates :slug,         presence: true, uniqueness: true
  validates :series_order, uniqueness: { scope: :series }, allow_nil: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  after_commit :expire_cache
  after_commit :notify_indexnow, if: -> { saved_change_to_published? && published? }

  # guide_path(guide) → /guides/purchase-and-inspection
  def to_param
    slug
  end

  # 시리즈 인덱스 표시용: "주제" 부분만 추출
  # Format A: "주제 — 완전정복 N편"  →  "주제"
  # Format B: "완전정복 N편 — 주제"  →  "주제"
  def series_episode_title
    return title unless series.present?
    t = title
    t = t.gsub(/ [—–\-] .*?완전정복 \d+편\s*$/, "")  # Format A 제거
    t = t.gsub(/^.*?완전정복 \d+편 [—–\-] /, "")      # Format B 제거
    t.strip
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
    Rails.cache.delete("guides/series/#{series}") if series.present?
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
