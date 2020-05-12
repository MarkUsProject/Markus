class GraderPermission < ApplicationRecord
  self.table_name = 'grader_permission'
  validates_presence_of :user_id
  validates_inclusion_of :delete_grace_period_deduction, in: [true, false]
end
