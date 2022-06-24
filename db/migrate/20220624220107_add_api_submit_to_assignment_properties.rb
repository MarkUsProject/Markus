class AddApiSubmitToAssignmentProperties < ActiveRecord::Migration[7.0]
  def change
    add_column :assignment_properties, :api_submit, :boolean
  end
end
