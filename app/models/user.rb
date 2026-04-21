class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable,
         :omniauthable, omniauth_providers: [ :kakao, :naver ]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email.presence || "#{auth.uid}@#{auth.provider}.silmu"
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name.presence || auth.info.nickname
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end

  has_one :calendar_datum, dependent: :destroy
  has_one :exam_progress, dependent: :destroy
  has_many :exam_question_comments, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :law_change_subscriptions, dependent: :nullify

  after_create_commit :send_welcome_email

  def admin?
    # DB 컬럼 우선, 환경변수 폴백 (점진적 전환)
    self[:admin] || email == ENV.fetch("ADMIN_EMAIL", "admin@silmu.kr")
  end

  private

  def send_welcome_email
    WelcomeMailer.welcome(self).deliver_later
  end
end
