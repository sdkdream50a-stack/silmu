class AddNewsletterAgreedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :newsletter_agreed, :boolean, default: false, null: false
  end
end
