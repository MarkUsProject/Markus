class AddSectionToUser < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :users, :sections
  end
end
