class RemoveCategoriesTable < ActiveRecord::Migration
  def self.up
    drop_table :categories
  end

  def self.down
    create_table :categories do |t|
      t.column    :name,   :text
      t.column    :token,  :text
      t.column    :ntoken, :int
    end
  end
end
