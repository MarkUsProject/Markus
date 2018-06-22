class AddNonRegeneratingTokens < ActiveRecord::Migration[4.2]
  def change
    change_table :assignments do |t|
      t.boolean :non_regenerating_tokens, default: false
    end
  end
end
