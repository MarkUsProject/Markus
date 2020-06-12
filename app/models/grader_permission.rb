# Contains the grader permissions for a particular grader
class GraderPermission < ApplicationRecord
  belongs_to :user
  validates_presence_of :user_id
end
