class EnforceNotNullOnGroupsGroupName < ActiveRecord::Migration[8.1]
  def change
    change_column_null :groups, :group_name, false
  end
end
