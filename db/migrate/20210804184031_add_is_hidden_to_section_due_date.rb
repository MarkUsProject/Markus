class AddIsHiddenToSectionDueDate < ActiveRecord::Migration[6.1]
  def change
    add_column :section_due_dates, :is_hidden, :boolean
  end
end
