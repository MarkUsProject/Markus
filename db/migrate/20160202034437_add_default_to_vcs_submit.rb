class AddDefaultToVcsSubmit < ActiveRecord::Migration[4.2]
  def up
    change_column_default :assignments, :vcs_submit, :false
  end

  def down
    change_column_default :assignments, :vcs_submit, :nil
  end
end
