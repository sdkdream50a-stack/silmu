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

  # 클릭 계측 — "결과를 보여줬는데 만족했는가" 측정
  scope :clicked, -> { where.not(clicked_at: nil) }
  # 결과는 있었으나 아무 결과도 클릭하지 않은 검색 = 불만족 신호
  scope :unsatisfied, -> { where(zero_result: false, clicked_at: nil) }
  # 결과를 클릭하지 못한 검색어 top (불만족 갭 후보)
  scope :unsatisfied_queries, ->(days = 7, limit: 20) {
    where(zero_result: false, clicked_at: nil)
      .where("created_at > ?", days.days.ago)
      .group(:query).order(Arel.sql("COUNT(*) DESC")).limit(limit).count
  }
end
