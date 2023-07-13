class IncreaseGroupNameLength < ActiveRecord::Migration[7.0]
  def change
    change_column :groups, :group_name, :string, {:limit => 100}
  end
end
