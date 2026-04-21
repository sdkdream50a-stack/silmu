class AddSectorToAuditCases < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_cases, :sector, :integer, default: 0, null: false
    add_index :audit_cases, [ :published, :sector ], name: "index_audit_cases_on_published_and_sector"
  end
end
