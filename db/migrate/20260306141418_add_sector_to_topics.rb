class AddSectorToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :sector, :integer, default: 0, null: false
    add_index :topics, [ :published, :sector ], name: "index_topics_on_published_and_sector"
    add_index :topics, [ :published, :sector, :category ], name: "index_topics_on_pub_sector_cat"
  end
end
