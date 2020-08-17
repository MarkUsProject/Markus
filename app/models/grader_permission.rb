# Contains the grader permissions for a particular grader
class GraderPermission < ApplicationRecord
  belongs_to :ta
  validates_presence_of :user_id
  validate :user_must_be_a_grader
  validates_associated :ta

  def user_must_be_a_grader
    unless Ta.exists?(id: self.user_id)
      errors.add('base', 'User must be a grader')
      false
    end
    true
  end
end
