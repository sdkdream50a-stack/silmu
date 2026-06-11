class AddSourceToSearchLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :search_logs, :source, :string, limit: 20
  end
end
