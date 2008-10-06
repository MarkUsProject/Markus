class RubricLevel < ActiveRecord::Base
  belongs_to  :rubric_criteria
  validates_associated      :rubric_criteria, :message => 'association is not strong with you'
  validates_presence_of :name, :weight, :assignment_id
end
