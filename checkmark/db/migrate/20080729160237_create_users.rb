class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column  :user_name,       :string,  :null => false
      t.column  :user_number,     :string,  :null => false
      t.column  :last_name,       :string
      t.column  :first_name,      :string
      t.column  :grace_days,      :int,     :null => true
      t.column  :role,            :string
      
      t.timestamps
    end
    
    add_index :users, :user_number, :unique => true
    add_index :users, :user_name, :unique => true
  end

  def self.down
    drop_table :users
  end
end