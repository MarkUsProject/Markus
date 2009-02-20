class RubricCriteria < ActiveRecord::Base
  belongs_to  :assignment
  has_many :rubric_levels
  validates_associated      :assignment, :message => 'association is not strong with an assignment'
  validates_uniqueness_of :name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :name, :weight, :assignment_id
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :weight, :message => "must be a number greater than 0.0", :greater_than => 0.0
end
