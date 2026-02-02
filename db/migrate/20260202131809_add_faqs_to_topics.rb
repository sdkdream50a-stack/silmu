class AddFaqsToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :faqs, :text
  end
end
