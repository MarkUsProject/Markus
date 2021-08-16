class ChangeDurationColumnsToIntervalTypes < ActiveRecord::Migration[6.1]
  def change
    change_column :assignment_properties, :duration, "interval USING CAST(duration as interval)"
    change_column :extensions, :time_delta, "interval USING CAST(time_delta as interval)"
  end
end
