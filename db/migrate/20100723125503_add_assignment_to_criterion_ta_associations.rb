class AddAssignmentToCriterionTaAssociations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :criterion_ta_associations, :assignment_id, :integer
  end

  def self.down
    remove_column :criterion_ta_associations, :assignment_id
  end
end
