class CreateContentMigrations < ActiveRecord::Migration[8.1]
  def change
    create_table :content_migrations do |t|
      t.string :filename, null: false
      t.datetime :applied_at
      t.string :status, null: false, default: "pending"
      t.text :error_message
      t.integer :duration_ms

      t.timestamps
    end

    add_index :content_migrations, :filename, unique: true
    add_index :content_migrations, :status
  end
end
