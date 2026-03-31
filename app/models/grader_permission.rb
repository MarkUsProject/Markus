# Contains the grader permissions for a particular grader
# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: grader_permissions
#
#  id                 :bigint           not null, primary key
#  manage_assessments :boolean          default(FALSE), not null
#  manage_submissions :boolean          default(FALSE), not null
#  run_tests          :boolean          default(FALSE), not null
#  role_id            :bigint           not null
#
# Indexes
#
#  index_grader_permissions_on_role_id  (role_id)
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class GraderPermission < ApplicationRecord
  belongs_to :ta, class_name: 'Ta', foreign_key: :role_id, inverse_of: :grader_permission
  has_one :course, through: :ta
end
