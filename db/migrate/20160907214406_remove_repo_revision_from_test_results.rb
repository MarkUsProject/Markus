class RemoveRepoRevisionFromTestResults < ActiveRecord::Migration
  def change
    remove_column :test_results, :repo_revision, :integer
  end
end
