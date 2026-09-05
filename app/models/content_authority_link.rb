# frozen_string_literal: true

# P1.5 §8·§13 — 콘텐츠 ↔ 근거 연결. Impact Graph 의 간선.
#
# Tool/Template 은 ActiveRecord 모델이 아니라 코드 기반이므로 content_key 로 참조한다(§34·§35).
class ContentAuthorityLink < ApplicationRecord
  belongs_to :authority_document

  AR_CONTENT_TYPES = %w[Topic Guide AuditCase].freeze
  KEYED_CONTENT_TYPES = %w[Tool Template].freeze
  CONTENT_TYPES = (AR_CONTENT_TYPES + KEYED_CONTENT_TYPES).freeze

  RELATIONSHIP_TYPES = {
    "GOVERNED_BY"     => "근거 법령",
    "INTERPRETS"      => "해석 대상",
    "EVIDENCED_BY"    => "사례 근거",
    "CALCULATES_WITH" => "계산 기준"
  }.freeze

  CONFIDENCES = %w[HIGH MEDIUM LOW].freeze

  validates :content_type, inclusion: { in: CONTENT_TYPES }
  validates :relationship_type, inclusion: { in: RELATIONSHIP_TYPES.keys }
  validates :confidence, inclusion: { in: CONFIDENCES }
  validate  :content_reference_present

  scope :for_content, ->(type, id_or_key) {
    if AR_CONTENT_TYPES.include?(type.to_s)
      where(content_type: type, content_id: id_or_key)
    else
      where(content_type: type, content_key: id_or_key)
    end
  }
  scope :high_confidence, -> { where(confidence: "HIGH") }

  def keyed? = KEYED_CONTENT_TYPES.include?(content_type)

  # 실제 콘텐츠 레코드 (AR 타입일 때만)
  def content_record
    return nil if keyed? || content_id.blank?

    content_type.constantize.find_by(id: content_id)
  end

  def label
    ref = [ article_reference, clause_reference ].compact_blank.join(" ")
    [ content_type, content_key.presence || content_id, ref.presence ].compact.join(" / ")
  end

  private

  def content_reference_present
    if keyed?
      errors.add(:content_key, "must be present for #{content_type}") if content_key.blank?
    elsif content_id.blank?
      errors.add(:content_id, "must be present for #{content_type}")
    end
  end
end
