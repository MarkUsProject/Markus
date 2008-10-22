class RubricCriteria < ActiveRecord::Base
  belongs_to  :assignment
  validates_associated      :assignment, :message => 'association is not strong with an assignment'
  validates_presence_of :name, :weight, :assignment_id
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :weight, :message => "must be a number greater than 0.0 and less than 1.0", :less_than_or_equal_to => 1.0, :greater_than => 0.0
end
