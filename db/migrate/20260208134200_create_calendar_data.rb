class CreateCalendarData < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_data do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :task_states, default: {}, null: false
      t.jsonb :custom_tasks, default: [], null: false
      t.jsonb :categories, default: {}, null: false
      t.timestamps
    end
  end
end
