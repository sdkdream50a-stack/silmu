class CreateSearchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :search_logs do |t|
      t.string :query, null: false, limit: 200
      t.integer :topic_count, default: 0, null: false
      t.integer :audit_case_count, default: 0, null: false
      t.integer :guide_count, default: 0, null: false
      t.integer :template_count, default: 0, null: false
      t.boolean :zero_result, default: false, null: false
      t.string :ip_hash
      t.timestamps
    end

    add_index :search_logs, :query
    add_index :search_logs, [ :zero_result, :created_at ]
    add_index :search_logs, :created_at
  end
end
