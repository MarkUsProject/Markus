# Contains the grader permissions for a particular grader
class GraderPermission < ApplicationRecord
  self.table_name = 'grader_permission'
  validates_presence_of :user_id
end
