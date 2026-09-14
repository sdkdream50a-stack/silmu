class LawChangeSubscription < ApplicationRecord
  # 글 귀속 키(source) = 네이버 글 logNo. 형식이 아니면 저장하지 않는다(NULL = UNMEASURED).
  SOURCE_POST_FORMAT = /\A\d{9,15}\z/

  belongs_to :user, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :topic_slug, presence: true
  validates :email, uniqueness: { scope: :topic_slug, message: "이미 구독 중입니다" }
  validates :source, format: { with: SOURCE_POST_FORMAT }, allow_nil: true

  # 클라이언트가 보낸 값은 믿지 않는다 — logNo 형식만 통과, 나머지(cta_card·캠페인명·빈 값)는 nil.
  def self.normalize_source_post(raw)
    value = raw.to_s.strip
    value.match?(SOURCE_POST_FORMAT) ? value : nil
  end
end
