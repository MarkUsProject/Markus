class RemoveRepoRevisionFromTestResults < ActiveRecord::Migration[4.2]
  def change
    remove_column :test_results, :repo_revision, :integer
  end
end
