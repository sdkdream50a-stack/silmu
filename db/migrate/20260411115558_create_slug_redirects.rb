class CreateSlugRedirects < ActiveRecord::Migration[8.1]
  def change
    create_table :slug_redirects do |t|
      t.string :old_slug, null: false
      t.string :new_slug, null: false
      t.string :resource_type, null: false

      t.timestamps
    end
    add_index :slug_redirects, [ :old_slug, :resource_type ], unique: true
  end
end
