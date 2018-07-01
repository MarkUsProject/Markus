class RenameScriptNameInTestScripts < ActiveRecord::Migration[4.2]
  def change
    rename_column :test_scripts, :script_name, :file_name
  end
end
