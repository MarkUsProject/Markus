class AddUniqueIndexToCoursesName < ActiveRecord::Migration[7.0]
  def up
    # no need to change any data since this should already have been enforced by a validation on courses
    add_index :courses, :name, unique: true
  end
  def down
    remove_index :courses, :name
  end
end
