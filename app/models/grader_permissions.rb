# Contains the grader permissions for a particular grader
class GraderPermissions < ApplicationRecord
  self.table_name = 'grader_permissions'
  validates_presence_of :user_id
end
