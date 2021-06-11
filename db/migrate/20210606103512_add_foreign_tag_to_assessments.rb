class AddForeignTagToAssessments < ActiveRecord::Migration[6.1]
  def change
    add_reference :tags, :assessments, index: true, foreign_key: true
  end
end
