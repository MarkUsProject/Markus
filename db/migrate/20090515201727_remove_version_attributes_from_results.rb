class RemoveVersionAttributesFromResults < ActiveRecord::Migration
  def self.up
    # remove attributes for result-versioning again (there is a wiki-page on that)
    remove_column :results, :result_version
    remove_column :results, :result_version_used
  end

  def self.down
    add_column :results, :result_version, :integer
    add_column :results, :result_version_used, :boolean
  end
end
