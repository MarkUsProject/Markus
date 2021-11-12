class AddCourseIdToMarkingScheme < ActiveRecord::Migration[6.1]
  def change
    add_reference :marking_schemes, :course, null: false, foreign_key: true
  end
end
