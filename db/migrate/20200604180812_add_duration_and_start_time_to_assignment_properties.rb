class AddDurationAndStartTimeToAssignmentProperties < ActiveRecord::Migration[6.0]
  def change
    add_column :assignment_properties, :duration, :string, null: true, default: nil
    add_column :assignment_properties, :start_time, :datetime, null: true, default: nil
    add_column :assignment_properties, :is_timed, :boolean, null: false, default: false
  end
end
