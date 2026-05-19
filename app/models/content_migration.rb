# P6 ContentMigration Phase 1 — patch 시드 → idempotent migration 인프라
#
# db/content_migrations/*.rb 파일을 한 번씩만 실행하는 추적 테이블.
# 기존 patch 시드의 누적 문제(어떤 시드가 적용됐는지 운영 DB로 확인 불가) 해소.
#
# 실행: bin/rake silmu:content_migrate
class ContentMigration < ApplicationRecord
  STATUSES = %w[pending applied failed].freeze

  validates :filename, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :applied, -> { where(status: "applied") }
  scope :failed,  -> { where(status: "failed") }
end
