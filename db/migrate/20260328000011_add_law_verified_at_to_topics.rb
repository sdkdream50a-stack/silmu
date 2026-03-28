class AddLawVerifiedAtToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :law_verified_at, :datetime
    add_column :topics, :law_base_date, :string
  end
end
