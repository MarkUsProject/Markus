class CreateCategories < ActiveRecord::Migration
  def self.up

      create_table :categories do |t|
        t.column    :name,   :text
        t.column    :token,  :text
        t.column    :ntoken, :int
      end

  end

  def self.down
    drop_table :categories
  end
end
