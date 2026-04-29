class AddOrgTypeToTopicsAndAuditCases < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :topics, :org_type, :integer unless column_exists?(:topics, :org_type)
    add_column :audit_cases, :org_type, :integer unless column_exists?(:audit_cases, :org_type)

    add_index :topics, [ :sector, :org_type ], algorithm: :concurrently, if_not_exists: true
    add_index :audit_cases, [ :sector, :org_type ], algorithm: :concurrently, if_not_exists: true
  end
end
