class ChangeTokenColumns < ActiveRecord::Migration
  def change
    change_table :assignments do |t|
      t.rename :tokens_per_day, :tokens_per_period
      t.rename :regeneration_period, :token_period
      t.rename :tokens_start_of_availability_date, :token_start_date
    end

    change_table :tokens do |t|
      t.rename :tokens, :remaining
      t.rename :last_token_used_date, :last_used
    end

    add_foreign_key :tokens, :groupings

    reversible do |dir|
      dir.up do
        change_column :tokens, :last_used, :datetime
        remove_column :assignments, :last_token_regeneration_date, :datetime
      end

      dir.down do
        change_column :tokens, :last_used, :date
        add_column :assignments, :last_token_regeneration_date, :datetime
      end
    end
  end
end
