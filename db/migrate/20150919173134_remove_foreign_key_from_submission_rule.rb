class RemoveForeignKeyFromSubmissionRule < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :submission_rules, :assignments
  end
end
