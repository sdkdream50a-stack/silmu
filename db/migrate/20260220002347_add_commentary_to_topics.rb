class AddCommentaryToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :commentary, :text
  end
end
