class AddRepeatedIssueToAuditCases < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_cases, :repeated_issue, :boolean, default: false
  end
end
