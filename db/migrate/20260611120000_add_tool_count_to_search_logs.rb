class AddToolCountToSearchLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :search_logs, :tool_count, :integer, default: 0, null: false
  end
end
