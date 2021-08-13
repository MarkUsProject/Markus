class UpdateDefaultSectionDueDateIsHidden < ActiveRecord::Migration[6.1]
  def change
    change_column_default :section_due_dates, :is_hidden, from: nil, to: false
    change_column_null :section_due_dates, :is_hidden, false, false
  end
end
