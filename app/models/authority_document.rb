# frozen_string_literal: true

# P1.5 §8 — 법령/규정 하나의 identity.
# 시점 snapshot 은 AuthorityVersion 이 갖는다. 이 모델은 "무엇인가"만 안다.
class AuthorityDocument < ApplicationRecord
  belongs_to :authority_source
  belongs_to :current_version, class_name: "AuthorityVersion", optional: true
  # ⚠️ 선언 순서 = 삭제 순서. change_events 가 versions 를 FK 로 참조하므로 먼저 지워야 한다.
  has_many :authority_change_events, dependent: :destroy
  has_many :content_authority_links, dependent: :destroy
  has_many :authority_versions, dependent: :destroy

  # §6 — 법령·규정·지침을 하나의 문자열로 취급하지 않는다.
  DOCUMENT_TYPES = {
    "CONSTITUTION"           => "헌법",
    "LAW"                    => "법률",
    "PRESIDENTIAL_DECREE"    => "대통령령(시행령)",
    "MINISTERIAL_ORDINANCE"  => "부령(시행규칙)",
    "LOCAL_ORDINANCE"        => "조례",
    "LOCAL_RULE"             => "규칙",
    "DIRECTIVE"              => "훈령",
    "REGULATION"             => "예규",
    "OFFICIAL_INSTRUCTION"   => "지시",
    "NOTICE"                 => "고시",
    "PUBLIC_NOTICE"          => "공고",
    "ADMINISTRATIVE_RULE"    => "행정규칙",
    "GUIDELINE"              => "지침",
    "MANUAL"                 => "업무편람",
    "HANDBOOK"               => "안내서",
    "FAQ"                    => "질의응답",
    "OFFICIAL_INTERPRETATION" => "유권해석",
    "AUDIT_STANDARD"         => "감사기준"
  }.freeze

  # 법제처 API 의 법령구분명 → 내부 타입
  KOREAN_TYPE_MAP = {
    "헌법" => "CONSTITUTION", "법률" => "LAW", "대통령령" => "PRESIDENTIAL_DECREE",
    "총리령" => "MINISTERIAL_ORDINANCE", "부령" => "MINISTERIAL_ORDINANCE",
    "훈령" => "DIRECTIVE", "예규" => "REGULATION", "고시" => "NOTICE", "지침" => "GUIDELINE"
  }.freeze

  STATUSES = %w[ACTIVE REPEALED UNKNOWN].freeze

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPES.keys }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "ACTIVE") }

  # current_version_id 가 versions 를 FK 로 참조하므로, 삭제 전에 먼저 끊어야 한다.
  # prepend: true — dependent: :destroy 콜백보다 앞서 실행되어야 한다.
  before_destroy :detach_current_version, prepend: true

  def self.document_type_for_korean(name) = KOREAN_TYPE_MAP[name.to_s.strip] || "ADMINISTRATIVE_RULE"

  def document_type_label = DOCUMENT_TYPES[document_type]
  def display_title = short_title.presence || title

  # 시행일 기준 정렬한 이력
  def version_history = authority_versions.order(fetched_at: :desc)

  # §9 — "개정되었는가"와 "지금 시행 중인가"는 다른 질문이다.
  # 오늘 기준으로 실제 시행 중인 버전(시행일이 도래한 것 중 가장 최근).
  def effective_version(on = Date.current)
    authority_versions
      .where.not(effective_at: nil)
      .where(effective_at: ..on)
      .order(effective_at: :desc, fetched_at: :desc)
      .first
  end

  # 공포·수집은 되었으나 아직 시행 전인 버전
  def pending_versions(on = Date.current)
    authority_versions.where(effective_at: (on + 1)..).order(:effective_at)
  end

  def pending_change? = pending_versions.exists?

  private

  def detach_current_version
    update_columns(current_version_id: nil) if current_version_id.present?
  end
end
