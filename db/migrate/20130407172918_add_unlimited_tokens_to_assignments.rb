class AddUnlimitedTokensToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    change_table :assignments do |t|
      t.boolean :unlimited_tokens, :default => false
    end
    Assignment.update_all ["unlimited_tokens = ?", false]
  end

  def self.down
    remove_column :assignments, :unlimited_tokens
  end
end
