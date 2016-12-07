class AddNonRegeneratingTokens < ActiveRecord::Migration
  def change
    change_table :assignments do |t|
      t.boolean :non_regenerating_tokens, default: false
    end
  end
end
