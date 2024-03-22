class AddTokenEndDateToAssignmentProperties < ActiveRecord::Migration[7.1]
  def change
    add_column :assignment_properties, :token_end_date, :datetime
  end
end
