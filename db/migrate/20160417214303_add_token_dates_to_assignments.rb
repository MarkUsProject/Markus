class AddTokenDatesToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :last_token_regeneration_date, :datetime
    add_column :assignments, :tokens_start_of_availability_date, :datetime
    add_column :assignments, :regeneration_period, :float
  end
end
