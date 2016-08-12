class RemoveMarkingSchemeTypeFromAssignment < ActiveRecord::Migration
  def change
    remove_column :assignments, :marking_scheme_type, :string, default: 'rubric'
  end
end
