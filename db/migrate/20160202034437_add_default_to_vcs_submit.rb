class AddDefaultToVcsSubmit < ActiveRecord::Migration
  def up
    change_column_default :assignments, :vcs_submit, :false
  end

  def down
    change_column_default :assignments, :vcs_submit, :nil
  end
end
