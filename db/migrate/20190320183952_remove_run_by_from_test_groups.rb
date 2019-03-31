class RemoveRunByFromTestGroups < ActiveRecord::Migration[5.2]
  def change
    change_table :test_groups do |t|
      t.remove :run_by_instructors, :run_by_students
    end
  end
end
