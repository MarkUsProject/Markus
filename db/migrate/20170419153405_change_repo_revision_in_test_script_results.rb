class ChangeRepoRevisionInTestScriptResults < ActiveRecord::Migration[4.2]
  def change
    change_column :test_script_results, :repo_revision, :text
  end
end
