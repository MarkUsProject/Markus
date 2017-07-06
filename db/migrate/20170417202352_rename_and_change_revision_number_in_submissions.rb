class RenameAndChangeRevisionNumberInSubmissions < ActiveRecord::Migration
  def change
    rename_column :submissions, :revision_number, :revision_identifier
    change_column :submissions, :revision_identifier, :text
  end
end
