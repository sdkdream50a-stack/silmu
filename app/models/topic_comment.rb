class TopicComment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :parent, class_name: "TopicComment", optional: true
  has_many   :replies, class_name: "TopicComment", foreign_key: :parent_id, dependent: :destroy

  enum :comment_type, { question: 0, answer: 1, comment: 2 }, default: :question

  validates :body, presence: true, length: { minimum: 5, maximum: 800 }
  validates :topic_slug, presence: true

  scope :visible,  -> { where(hidden: false) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :by_topic, ->(slug) { where(topic_slug: slug).visible.top_level.order(is_official: :desc, likes_count: :desc, created_at: :desc) }

  def author_name
    user&.email&.split("@")&.first&.then { |n| n.length > 8 ? "#{n[0..4]}***" : n } || "익명"
  end

  # Claude Haiku로 댓글 품질 자동 검증 (ExamQuestionComment 패턴 재사용)
  def self.moderate_with_ai(body)
    client = Anthropic::Client.new
    response = client.messages(
      model: "claude-haiku-4-5-20251001",
      max_tokens: 100,
      messages: [ {
        role: "user",
        content: <<~PROMPT
          공무원 실무 Q&A 댓글 적합성을 판단해주세요.

          댓글: #{body}

          아래 기준으로 평가 후 JSON만 반환하세요 (다른 텍스트 없이):
          {"approved": true/false, "reason": "거부 이유(30자 이내, 통과 시 null)"}

          거부 기준: 욕설·혐오, 스팸·광고, 개인정보 포함, 공무원 업무와 전혀 무관한 내용
          허용: 실무 질문, 법령 해석, 업무 경험 공유, 오류 지적
        PROMPT
      } ]
    )
    raw = response.content.first.text.gsub(/```json\n?|\n?```/, "").strip
    JSON.parse(raw)
  rescue => e
    Rails.logger.warn "[TopicCommentModeration] AI 오류 (허용 처리): #{e.message}"
    { "approved" => true, "reason" => nil }
  end
end
