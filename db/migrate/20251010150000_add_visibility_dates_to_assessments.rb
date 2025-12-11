class AddVisibilityDatesToAssessments < ActiveRecord::Migration[7.1]
  def change
    add_column :assessments, :visible_on, :datetime
    add_column :assessments, :visible_until, :datetime
    add_column :assessment_section_properties, :visible_on, :datetime
    add_column :assessment_section_properties, :visible_until, :datetime
  end
end
