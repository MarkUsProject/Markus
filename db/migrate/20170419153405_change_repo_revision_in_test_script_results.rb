class ChangeRepoRevisionInTestScriptResults < ActiveRecord::Migration
  def change
    change_column :test_script_results, :repo_revision, :text
  end
end
