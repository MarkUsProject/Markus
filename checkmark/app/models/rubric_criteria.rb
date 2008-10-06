class RubricCriteria < ActiveRecord::Base
  belongs_to  :assignment
  validates_associated      :assignment, :message => 'association is not strong with you'
  validates_presence_of :name, :weight, :assignment_id
  validates_numericality_of :assignment_id, :only_integer => true, :message => "can only be whole number."
  validates_numericality_of :weight, :message => "must be a number."
  
  def validate
      errors.add(:assignment_id, 'should not be a negative value') if assignment_id.nil?|| assignment_id < 0
      errors.add(:weight, 'should be a positive value') if weight.nil? || (weight <= 0)
      errors.add(:weight, 'should be between 0.0 and 1.0') if weight <= 0.0 || weight > 1.0
  end
end
