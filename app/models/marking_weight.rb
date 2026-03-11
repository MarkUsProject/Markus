# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: marking_weights
#
#  id                :integer          not null, primary key
#  weight            :decimal(, )
#  created_at        :datetime
#  updated_at        :datetime
#  assessment_id     :bigint           not null
#  marking_scheme_id :integer
#
# Indexes
#
#  index_marking_weights_on_assessment_id  (assessment_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class MarkingWeight < ApplicationRecord
  belongs_to :marking_scheme
  belongs_to :assessment
  has_one :course, through: :assessment
  validate :courses_should_match
end
