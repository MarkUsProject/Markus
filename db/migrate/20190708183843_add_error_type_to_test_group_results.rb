class AddErrorTypeToTestGroupResults < ActiveRecord::Migration[5.2]
  def change
    add_column :test_group_results, :error_type, :string
  end
end
