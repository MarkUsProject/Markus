class RedoAddForeignTagToAssessments < ActiveRecord::Migration[6.1]
  def change
    remove_reference :tags, :assessments, index: true, foreign_key: true
    add_reference :tags, :assessment, index: true, foreign_key: true
  end
end
