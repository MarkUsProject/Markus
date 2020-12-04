# Contains the grader permissions for a particular grader
class GraderPermission < ApplicationRecord
  belongs_to :ta, class_name: 'Ta', foreign_key: :user_id, inverse_of: :grader_permission
end
