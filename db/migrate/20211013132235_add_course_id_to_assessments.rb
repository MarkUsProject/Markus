class AddCourseIdToAssessments < ActiveRecord::Migration[6.1]
  def change
    add_reference :assessments, :course, null: false, foreign_key: true
  end
end
