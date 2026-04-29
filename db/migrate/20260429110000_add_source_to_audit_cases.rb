class AddSourceToAuditCases < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :audit_cases, :source, :jsonb, default: {} unless column_exists?(:audit_cases, :source)
    add_index :audit_cases, :source, using: :gin, algorithm: :concurrently, if_not_exists: true
  end
end
