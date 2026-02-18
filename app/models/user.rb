class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :calendar_datum, dependent: :destroy

  after_create_commit :send_welcome_email

  private

  def send_welcome_email
    WelcomeMailer.welcome(self).deliver_later
  end
end
