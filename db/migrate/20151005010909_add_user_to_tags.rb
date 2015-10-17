class AddUserToTags < ActiveRecord::Migration
  def change
    add_reference :tags, :user, index: true, foreign_key: true
  end
end
