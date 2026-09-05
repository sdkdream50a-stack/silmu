# frozen_string_literal: true

# P1.5 §16 — 감시 대상 공식 출처 등록부.
# 처음부터 인터넷 전체를 감시하지 않는다. 등록된 것만 본다.
class AuthoritySource < ApplicationRecord
  has_many :authority_documents, dependent: :restrict_with_error

  # §18 — structured 와 unstructured 를 같은 parser 로 처리하지 않는다.
  SOURCE_TYPES = {
    "STRUCTURED_API"   => "구조화 API (법제처 OPEN API 등)",
    "STRUCTURED_HTML"  => "구조화 HTML",
    "UNSTRUCTURED_PDF" => "비구조 PDF (지침·편람)",
    "UNSTRUCTURED_HTML" => "비구조 HTML (공지·FAQ)"
  }.freeze

  FETCH_STRATEGIES = %w[law_api http_html http_pdf manual].freeze

  # §24 — 사이트 장애를 "법령 삭제"로 해석하면 안 된다.
  FAILURE_KINDS = %w[FETCH_FAILED PARSE_FAILED SOURCE_UNAVAILABLE].freeze

  # §7 — Tier 4(카페·블로그)는 현행성 판정 근거로 쓰지 않는다.
  TIER_LABELS = {
    1 => "Tier 1 · 1차 공식기관",
    2 => "Tier 2 · 지방/기관 공식자료",
    3 => "Tier 3 · 전문기관 공식 해설",
    4 => "Tier 4 · 커뮤니티 (현행성 근거로 사용 불가)"
  }.freeze

  validates :key, presence: true, uniqueness: true
  validates :name, :source_type, :fetch_strategy, presence: true
  validates :source_type, inclusion: { in: SOURCE_TYPES.keys }
  validates :fetch_strategy, inclusion: { in: FETCH_STRATEGIES }
  validates :authority_tier, inclusion: { in: 1..4 }
  validates :check_interval_hours, numericality: { greater_than: 0 }

  scope :enabled, -> { where(enabled: true) }
  scope :structured, -> { where(source_type: %w[STRUCTURED_API STRUCTURED_HTML]) }
  scope :unstructured, -> { where(source_type: %w[UNSTRUCTURED_PDF UNSTRUCTURED_HTML]) }

  # §23 — 소스마다 주기가 다르다. 지금 검사할 때가 됐는가.
  def due?(now = Time.current)
    return false unless enabled?
    return true if last_checked_at.blank?

    last_checked_at <= now - check_interval_hours.hours
  end

  # §7 — 현행성 판정의 근거로 삼을 수 있는 등급인가
  def usable_for_currency_judgement? = authority_tier <= 3

  def tier_label = TIER_LABELS[authority_tier]

  # P1.55B §10 — 연속 실패가 이 횟수에 이르면 운영자에게 1회 알린다.
  # AuthorityFreshnessCheckJob::MAX_CONSECUTIVE_FAILURES(5) 에서 잡이 소스를 건너뛰므로,
  # 그 전에 알리지 않으면 사람이 알 기회 자체가 없다.
  ALERT_THRESHOLD = 3

  # 성공은 장애 episode 를 닫는다 — 알림 이력도 함께 초기화해 다음 episode 에 다시 알릴 수 있게 한다.
  def record_success!(at: Time.current)
    update!(last_checked_at: at, last_success_at: at, failure_count: 0,
            last_failure_kind: nil, last_failure_message: nil,
            first_failed_at: nil, alerted_at: nil)
  end

  # §25 — 무한 retry 금지. 실패는 카운트하고 종류를 구분해 남긴다.
  # first_failed_at 은 episode 최초 실패에만 찍고 이후 실패로 옮기지 않는다(지속 시간 관측용).
  def record_failure!(kind, message, at: Time.current)
    update!(last_checked_at: at, failure_count: failure_count + 1,
            last_failure_kind: kind, last_failure_message: message.to_s.truncate(1000),
            first_failed_at: first_failed_at || at)
  end

  # 알릴 때가 됐는가 — 임계값 도달 + 이 episode 에서 아직 안 알림
  def alert_due? = failure_count >= ALERT_THRESHOLD && alerted_at.nil?

  def mark_alerted!(at: Time.current) = update!(alerted_at: at)
end
