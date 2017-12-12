class RenameScriptNameInTestScripts < ActiveRecord::Migration
  def change
    rename_column :test_scripts, :script_name, :file_name
  end
end
