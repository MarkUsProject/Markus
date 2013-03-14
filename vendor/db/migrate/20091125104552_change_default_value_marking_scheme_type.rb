class ChangeDefaultValueMarkingSchemeType < ActiveRecord::Migration
  def self.up
    change_column :assignments, :marking_scheme_type, :string, :default => 'rubric'
  end

  def self.down
    change_column :assignments, :marking_scheme_type, :string, :default => nil
  end
end
