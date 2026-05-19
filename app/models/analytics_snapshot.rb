# P8 ROI 계측 — GA4 페이지별 지표 스냅샷
#
# metrics 예시: { "pageviews" => 142, "users" => 96, "avg_duration" => 73.4, "bounce_rate" => 42.1 }

class AnalyticsSnapshot < ApplicationRecord
  validates :label, :page_path, :captured_at, presence: true
  validates :days, numericality: { greater_than: 0 }

  scope :for_label, ->(l) { where(label: l) }
  scope :recent,    -> { order(captured_at: :desc) }

  def pageviews    = metrics["pageviews"].to_i
  def users        = metrics["users"].to_i
  def avg_duration = metrics["avg_duration"].to_f
  def bounce_rate  = metrics["bounce_rate"].to_f
end
