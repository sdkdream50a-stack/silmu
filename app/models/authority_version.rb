# frozen_string_literal: true

# P1.5 §8·§19 — 시점 snapshot. **IMMUTABLE.**
#
# 기존 snapshot 을 덮어쓰지 않는다. 그래야 "그때 우리가 무엇을 보고 검증했는가"를
# 나중에 되짚을 수 있다. 이 불변성이 깨지면 현행화 이력 전체가 신뢰를 잃는다.
class AuthorityVersion < ApplicationRecord
  belongs_to :authority_document

  validates :content_hash, :fetched_at, presence: true

  # ── IMMUTABILITY ──────────────────────────────────────────
  # 생성 후에는 어떤 컬럼도 바꿀 수 없다. 정정이 필요하면 새 버전을 만든다.
  before_update :reject_mutation
  before_destroy :allow_destroy_only_with_document

  class ImmutableError < StandardError; end

  scope :effective_on, ->(date) { where(effective_at: ..date).where.not(effective_at: nil) }
  scope :future_effective, -> { where(effective_at: (Date.current + 1)..) }

  def self.digest(normalized_content)
    Digest::SHA256.hexdigest(normalized_content.to_s)
  end

  # §9 — 지금 시행 중인가
  def in_effect?(on = Date.current)
    return false if effective_at.blank?
    return false if effective_at > on
    return false if expires_at.present? && expires_at <= on

    true
  end

  def future_effective?(on = Date.current) = effective_at.present? && effective_at > on

  def effective_label
    return "시행일 미상" if effective_at.blank?
    return "#{effective_at.strftime('%Y.%m.%d')} 시행 예정" if future_effective?

    "#{effective_at.strftime('%Y.%m.%d')} 시행"
  end

  private

  def reject_mutation
    raise ImmutableError,
          "AuthorityVersion##{id} 은 immutable 이다. 변경 대신 새 버전을 생성하라 " \
          "(변경 시도 컬럼: #{changed.join(', ')})"
  end

  # 문서 자체가 삭제되는 경우(dependent: :destroy)에만 허용한다.
  def allow_destroy_only_with_document
    return if destroyed_by_association.present?

    raise ImmutableError, "AuthorityVersion 은 개별 삭제할 수 없다 (문서 삭제 시에만 함께 제거된다)"
  end
end
