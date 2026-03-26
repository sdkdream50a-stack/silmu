class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :calendar_datum, dependent: :destroy
  has_one :exam_progress, dependent: :destroy
  has_many :exam_question_comments, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :law_change_subscriptions, dependent: :nullify

  after_create_commit :send_welcome_email

  def admin?
    email == ENV.fetch("ADMIN_EMAIL", "admin@silmu.kr")
  end

  private

  def send_welcome_email
    WelcomeMailer.welcome(self).deliver_later
  end
end
