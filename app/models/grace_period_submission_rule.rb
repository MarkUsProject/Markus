class GracePeriodSubmissionRule < SubmissionRule
  # This message will be displayed to Students on viewing their file manager
  # after the due date has passed, but before the calculated collection date.
  def overtime_message(grouping)
    # We need to know how many grace credits this grouping has left...
    grace_credits_remaining = grouping.available_grace_credits
    # How far are we into overtime?
    overtime_hours = calculate_overtime_hours_from(Time.current, grouping)
    grace_credits_to_use = calculate_deduction_amount(overtime_hours)
    if grace_credits_remaining < grace_credits_to_use
      # This grouping doesn't have enough grace credits.
      I18n.t 'grace_period_submission_rules.overtime_message_without_credits_left'
    else
      # This grouping has enough grace credits to spend.
      I18n.t 'grace_period_submission_rules.overtime_message_with_credits_left',
             grace_credits_remaining: grace_credits_remaining, grace_credits_to_use: grace_credits_to_use
    end
  end

  def apply_submission_rule(submission)
    return submission if submission.is_empty
    due_date = submission.grouping.due_date
    # If we aren't overtime, we don't need to apply a rule
    return submission if submission.revision_timestamp <= due_date

    # So we're overtime.  How far are we overtime?
    collection_time = submission.revision_timestamp
    grouping = submission.grouping
    overtime_hours = calculate_overtime_hours_from(collection_time, grouping)
    # Now we need to figure out how many Grace Credits to deduct
    deduction_amount = calculate_deduction_amount(overtime_hours)

    # Get rid of any previous deductions for this assignment, so as not to
    # give duplicate deductions upon multiple calls to this method
    remove_deductions(grouping)

    # And how many grace credits are available to this grouping
    available_grace_credits = submission.grouping.available_grace_credits

    # If the available_grace_creidts <= 0, simply get the submission
    # from the due date.
    # If the deduction_amount is greater than the amount of grace
    # credits available to this grouping, then we need to destroy
    # this submission, find the date of the last valid commit, and
    # use that as a submission, and return it.

    if available_grace_credits <= 0
      grouping = submission.grouping
      submission.destroy
      submission = Submission.create_by_timestamp(grouping, due_date.localtime)
      return submission
    elsif available_grace_credits < deduction_amount
      grouping = submission.grouping
      submission.destroy
      collection_time = calculate_collection_date_from_credits(available_grace_credits, due_date)
      submission = Submission.create_by_timestamp(grouping, collection_time.localtime)
      # And now, a little recursion...
      return assignment.submission_rule.apply_submission_rule(submission)
    end

    # Deduct Grace Credits from every member of the Grouping
    student_memberships = submission.grouping.accepted_student_memberships

    student_memberships.each do |student_membership|
      deduction = GracePeriodDeduction.new
      deduction.membership = student_membership
      deduction.deduction = deduction_amount
      deduction.save
    end

    submission
  end

  # Remove all deductions for this assignment from all accepted members of
  # grouping, so that any new deductions for the assignemnt will not be duplicates
  def remove_deductions(grouping)
    student_memberships = grouping.accepted_student_memberships

    student_memberships.each do |student_membership|
      deductions = student_membership.role.grace_period_deductions
      deductions.each do |deduction|
        if deduction.membership.grouping.assignment.id == assignment.id
          student_membership.grace_period_deductions.delete(deduction)
          deduction.destroy
        end
      end
      deductions.reload
    end
  end

  private

  def hours_sum
    periods.sum('hours')
  end

  # Given a certain number of hours into the grace periods, calculate how many credits to
  # deduct
  def calculate_deduction_amount(overtime_hours)
    return 0 if overtime_hours <= 0
    total_deduction = 0
    periods.each do |period|
      total_deduction += 1
      overtime_hours -= period.hours
      break if overtime_hours <= 0
    end
    total_deduction
  end

  # Given the number of credits remaining, calculate the collection_date
  # for a Submission
  def calculate_collection_date_from_credits(grace_credits, due_date)
    hours_after_due_date = 0
    periods.each do |period|
      hours_after_due_date += period.hours
      grace_credits -= 1
      break if grace_credits == 0
    end
    due_date + hours_after_due_date.hours
  end
end
