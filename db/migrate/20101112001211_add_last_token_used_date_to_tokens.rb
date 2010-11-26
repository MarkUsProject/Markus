class AddLastTokenUsedDateToTokens < ActiveRecord::Migration
  def self.up
    # column to store the last time a token was used
    add_column :tokens, :last_token_used_date, :date
  end

  def self.down
    remove_column :tokens, :last_token_used_date
  end
end

