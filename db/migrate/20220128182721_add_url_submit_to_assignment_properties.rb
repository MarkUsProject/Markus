class AddUrlSubmitToAssignmentProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :assignment_properties, :url_submit, :boolean, default: false, null: false
  end
end
