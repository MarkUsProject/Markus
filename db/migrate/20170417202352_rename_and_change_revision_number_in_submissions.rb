class RenameAndChangeRevisionNumberInSubmissions < ActiveRecord::Migration[4.2]
  def change
    rename_column :submissions, :revision_number, :revision_identifier
    change_column :submissions, :revision_identifier, :text
  end
end
