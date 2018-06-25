class RemoveMarkingSchemeTypeFromAssignment < ActiveRecord::Migration[4.2]
  def change
    remove_column :assignments, :marking_scheme_type, :string, default: 'rubric'
  end
end
