class CreateLaws < ActiveRecord::Migration[8.1]
  def change
    create_table :laws do |t|
      t.string :law_id
      t.string :name
      t.string :law_type
      t.text :content
      t.date :effective_date
      t.string :ministry

      t.timestamps
    end
    add_index :laws, :law_id
    add_index :laws, :law_type
  end
end
