# Contains the grader permissions for a particular grader
class GraderPermission < ApplicationRecord
  belongs_to :user
  validates_presence_of :user_id
  validate :user_must_be_a_grader
  validates_associated :user

  def user_must_be_a_grader
    return unless user && !user.is_a?(Ta)

    errors.add('base', 'User must be a grader')
    false
  end
end
