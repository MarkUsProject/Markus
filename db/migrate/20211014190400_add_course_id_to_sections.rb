class AddCourseIdToSections < ActiveRecord::Migration[6.1]
  def change
    add_reference :sections, :course, null: false, foreign_key: true
  end
end
