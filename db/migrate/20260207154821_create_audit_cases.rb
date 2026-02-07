class CreateAuditCases < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_cases do |t|
      t.string :slug
      t.string :title
      t.string :category
      t.string :severity
      t.text :issue
      t.string :legal_basis
      t.text :action_taken
      t.text :lesson
      t.text :detail
      t.string :topic_slug
      t.boolean :published, default: true
      t.integer :view_count, default: 0

      t.timestamps
    end
    add_index :audit_cases, :slug, unique: true
  end
end
