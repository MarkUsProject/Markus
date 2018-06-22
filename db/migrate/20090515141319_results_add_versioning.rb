class ResultsAddVersioning < ActiveRecord::Migration[4.2]
  def self.up
    add_column :results, :result_version, :integer
    add_column :results, :result_version_used, :boolean
  end

  def self.down
    remove_column :results, :result_version_used
    remove_column :results, :result_version
  end
end
