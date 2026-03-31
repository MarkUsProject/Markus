# The NoLateSubmissionRule applies no penalties whatsoever.  The collection
# time is on the due date of the assignment + allow_submit_until

# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: submission_rules
#
#  id            :integer          not null, primary key
#  penalty_type  :string           default("percentage")
#  type          :string           default("NoLateSubmissionRule")
#  created_at    :datetime
#  updated_at    :datetime
#  assessment_id :bigint           not null
#
# Indexes
#
#  index_submission_rules_on_assessment_id  (assessment_id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class NoLateSubmissionRule < SubmissionRule
  def overtime_message(_grouping)
    NoLateSubmissionRule.human_attribute_name(:after_collection_message)
  end

  # The NoLateSubmissionRule will not add any penalties
  def apply_submission_rule(submission)
    submission
  end
end
