class RemoveRunOnSubmissionFromTestScripts < ActiveRecord::Migration
  def change
    remove_column :test_scripts, :run_on_submission, :boolean
  end
end
