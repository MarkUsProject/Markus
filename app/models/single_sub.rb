class SingleSub < ActiveJob::Base

  queue_as :test_job

  def apply_penalty_or_add_grace_credits(grouping,
                                         apply_late_penalty,
                                         new_submission)
    if grouping.assignment.submission_rule.is_a? GracePeriodSubmissionRule
      # Return any grace credits previously deducted for this grouping.
      grouping.assignment.submission_rule.remove_deductions(new_submission)
    end
    if apply_late_penalty
      grouping.assignment.submission_rule.apply_submission_rule(new_submission)
    end
 end

  def perform(grouping, rev_num, apply_late_penalty, new_sub)
      grouping.is_collected = false
      #Grouping.assign_tas(grouping_ids, ta_ids, assignment)
      #remove_grouping_from_queue(grouping)
      grouping.save
      
      apply_penalty_or_add_grace_credits(grouping,
                                         apply_late_penalty,
                                         new_sub)
      grouping.is_collected = true
      grouping.save
  end
  
end