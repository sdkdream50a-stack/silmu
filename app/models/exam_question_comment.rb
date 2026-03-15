class ExamQuestionComment < ApplicationRecord
  belongs_to :user

  validates :body, presence: true, length: { maximum: 500 }
  validates :question_id, presence: true

  scope :visible, -> { where(hidden: false) }
  scope :by_question, ->(qid) { where(question_id: qid).visible.order(likes_count: :desc, created_at: :desc) }

  def author_display_name
    author_name.presence || "조달수험생#{user_id}"
  end

  # Claude Haiku로 댓글 품질 자동 검증
  # 반환: { approved: true/false, reason: "거부 이유" }
  def self.moderate_with_ai(body, question_text)
    client = Anthropic::Client.new
    response = client.messages(
      model: "claude-haiku-4-5-20251001",
      max_tokens: 100,
      messages: [ {
        role: "user",
        content: <<~PROMPT
          공공조달관리사 시험 Q&A 댓글 적합성을 판단해주세요.

          문제: #{question_text.to_s.first(200)}
          댓글: #{body}

          아래 기준으로 평가 후 JSON만 반환하세요 (다른 텍스트 없이):
          {"approved": true/false, "reason": "거부 이유(30자 이내, 통과 시 null)"}

          거부 기준: 욕설·혐오, 스팸·광고, 시험과 전혀 무관한 내용, 개인정보 포함
          허용: 문제 풀이 관련 질문, 법령 보충 설명, 학습 팁, 오류 지적
        PROMPT
      } ]
    )
    raw = response.content.first.text.gsub(/```json\n?|\n?```/, "").strip
    JSON.parse(raw)
  rescue => e
    Rails.logger.warn "[CommentModeration] AI 오류 (허용 처리): #{e.message}"
    { "approved" => true, "reason" => nil }
  end
end
