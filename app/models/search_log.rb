# frozen_string_literal: true

# silmu 검색 로깅 — 콘텐츠 갭 후보 자동 발굴 기반
# query 입력 + 4종 매칭 카운트 + zero_result 플래그
class SearchLog < ApplicationRecord
  validates :query, presence: true, length: { minimum: 2, maximum: 200 }

  scope :zero_result_recent, ->(days = 7) {
    where(zero_result: true).where("created_at > ?", days.days.ago)
  }

  scope :content_gap_candidates, ->(days = 7, limit: 20) {
    zero_result_recent(days).group(:query).order(Arel.sql("COUNT(*) DESC")).limit(limit).count
  }
end
