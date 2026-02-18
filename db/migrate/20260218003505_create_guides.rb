# Created: 2026-02-18 00:35
class CreateGuides < ActiveRecord::Migration[8.1]
  def change
    create_table :guides do |t|
      t.string   :title,          null: false
      t.string   :slug,           null: false
      t.string   :category
      t.string   :category_color, default: "emerald"
      t.string   :badge
      t.string   :tag
      t.text     :summary
      t.text     :description
      t.string   :author,         default: "실무팀"
      t.date     :published_on
      t.integer  :view_count,     default: 0, null: false
      t.jsonb    :sections
      t.string   :external_link
      t.boolean  :published,      default: true, null: false
      t.integer  :sort_order,     default: 0, null: false

      t.timestamps
    end

    add_index :guides, :slug,       unique: true
    add_index :guides, :published
    add_index :guides, :sort_order
    add_index :guides, :category
  end
end
