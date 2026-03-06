class AddInfographicUrlToAuditCases < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_cases, :infographic_url, :string
  end
end
