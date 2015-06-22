class ChangeMsIdColumnName < ActiveRecord::Migration
  def up
    rename_column :marking_weights, :ms_id, :marking_scheme_id
  end

  def down
  end
end
