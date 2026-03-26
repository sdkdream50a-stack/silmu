class LawChangeSubscription < ApplicationRecord
  belongs_to :user, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :topic_slug, presence: true
  validates :email, uniqueness: { scope: :topic_slug, message: "이미 구독 중입니다" }
end
