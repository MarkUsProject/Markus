class RemoveForeignKeyFromSubmissionRule < ActiveRecord::Migration
  def change
    remove_foreign_key :submission_rules, :assignments
  end
end
