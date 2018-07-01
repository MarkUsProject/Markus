class AddErrorToGrouping < ActiveRecord::Migration[4.2]
  def change
    # Error column for a submission file.
    add_column :groupings, :error_collecting, :boolean, :default => false
  end
end
