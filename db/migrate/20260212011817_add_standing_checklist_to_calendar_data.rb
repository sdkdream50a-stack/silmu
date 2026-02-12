class AddStandingChecklistToCalendarData < ActiveRecord::Migration[8.1]
  def change
    add_column :calendar_data, :standing_checklist, :jsonb, default: [], null: false
  end
end
