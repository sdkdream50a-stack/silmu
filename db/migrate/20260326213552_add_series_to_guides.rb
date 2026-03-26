class AddSeriesToGuides < ActiveRecord::Migration[8.1]
  def change
    add_column :guides, :series, :string
    add_column :guides, :series_order, :integer
    add_index :guides, [ :series, :series_order ], where: "series IS NOT NULL"
  end
end
