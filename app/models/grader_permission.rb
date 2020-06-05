# Contains the grader permissions for a particular grader
class GraderPermission < ApplicationRecord
  self.table_name = 'grader_permissions'
  belongs_to :user
  validates_presence_of :user_id
end
