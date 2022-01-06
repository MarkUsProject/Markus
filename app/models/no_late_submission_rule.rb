# The NoLateSubmissionRule applies no penalties whatsoever.  The collection
# time is on the due date of the assignment + allow_submit_until

class NoLateSubmissionRule < SubmissionRule
  def overtime_message(_grouping)
    NoLateSubmissionRule.human_attribute_name(:after_collection_message)
  end

  # The NoLateSubmissionRule will not add any penalties
  def apply_submission_rule(submission)
    submission
  end
end
