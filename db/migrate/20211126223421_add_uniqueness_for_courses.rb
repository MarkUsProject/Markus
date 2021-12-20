class AddUniquenessForCourses < ActiveRecord::Migration[6.1]
  def change
    add_index :sections, [:name, :course_id], unique: true
    add_index :assessments, [:short_identifier, :course_id], unique: true
  end
end
