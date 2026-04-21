class AddSectorAndTopicSlugToGuides < ActiveRecord::Migration[8.1]
  def change
    add_column :guides, :sector, :integer, default: 0, null: false
    add_column :guides, :topic_slug, :string
    add_index :guides, [ :published, :sector ], name: "index_guides_on_published_and_sector"
    add_index :guides, :topic_slug, name: "index_guides_on_topic_slug"
  end
end
