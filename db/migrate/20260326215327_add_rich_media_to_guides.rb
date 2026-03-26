class AddRichMediaToGuides < ActiveRecord::Migration[8.1]
  def change
    add_column :guides, :rich_media, :jsonb, default: {}
    add_index :guides, :rich_media, using: :gin
  end
end
