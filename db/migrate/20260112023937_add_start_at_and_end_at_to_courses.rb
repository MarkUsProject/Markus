class AddStartAtAndEndAtToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :start_at, :datetime, null: true, default: nil
    add_column :courses, :end_at, :datetime, null: true, default: nil
  end
end
