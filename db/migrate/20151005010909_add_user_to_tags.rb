class AddUserToTags < ActiveRecord::Migration[4.2]
  def change
    add_reference :tags, :user, index: true, foreign_key: true
  end
end
