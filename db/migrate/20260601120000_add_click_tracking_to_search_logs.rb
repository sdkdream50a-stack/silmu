class AddClickTrackingToSearchLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :search_logs, :clicked_at, :datetime
    add_column :search_logs, :clicked_result_type, :string
    add_column :search_logs, :clicked_result_rank, :integer
  end
end
