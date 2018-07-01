class CreateSections < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sections do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :sections
  end
end
