class AddStartTimeAccessToSectionDueDates < ActiveRecord::Migration[6.0]
  def change
    add_column :section_due_dates, :start_time, :datetime, null: true, default: nil
  end
end
