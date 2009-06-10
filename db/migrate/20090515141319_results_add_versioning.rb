class ResultsAddVersioning < ActiveRecord::Migration
  def self.up
    add_column :results, :result_version, :integer
    add_column :results, :result_version_used, :boolean
  end

  def self.down
    remove_column :results, :result_version_used
    remove_column :results, :result_version
  end
end
