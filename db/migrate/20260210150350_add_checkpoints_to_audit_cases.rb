class AddCheckpointsToAuditCases < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_cases, :checkpoints, :text
  end
end
