class AddDeletedDefaultTasksToCalendarData < ActiveRecord::Migration[8.1]
  def change
    add_column :calendar_data, :deleted_default_tasks, :json
  end
end
