class CreateTaskGuides < ActiveRecord::Migration[8.1]
  def change
    create_table :task_guides do |t|
      t.string :task_title, null: false
      t.string :category
      t.text :content
      t.integer :status, default: 0
      t.timestamps
    end
    add_index :task_guides, :task_title, unique: true
  end
end
