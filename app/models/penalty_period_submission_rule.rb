class PenaltyPeriodSubmissionRule < SubmissionRule

  # This message will be dislayed to Students on viewing their file manager
  # after the due date has passed, but before the calculated collection date.
  def overtime_message(grouping)
    # How far are we into overtime?
    overtime_hours = calculate_overtime_hours_from(Time.zone.now, grouping)
    # Calculate the penalty that the grouping will suffer
    potential_penalty = calculate_penalty(overtime_hours)

    I18n.t 'penalty_period_submission_rules.overtime_message', potential_penalty: potential_penalty
  end


  # GracePeriodSubmissionRule works with all Assignments
  def assignment_valid?
    !assignment.nil?
  end

  def apply_submission_rule(submission)
    # Calculate the appropriate penalty, and attach the ExtraMark to the
    # submission Result
    return submission if submission.is_empty
    result = submission.get_original_result
    overtime_hours = calculate_overtime_hours_from(submission.revision_timestamp, submission.grouping)
    penalty_amount = calculate_penalty(overtime_hours)
    if penalty_amount.positive?
      ExtraMark.create(result: result,
                       extra_mark: -penalty_amount,
                       unit: ExtraMark::PERCENTAGE,
                       description: I18n.t('penalty_period_submission_rules.extramark_description',
                                           overtime_hours: overtime_hours, penalty_amount: penalty_amount))
    end

    submission
  end

  private

  def hours_sum
    periods.sum('hours')
  end

  def maximum_penalty
    periods.sum('deduction')
  end

  # Given a number of overtime_hours, calculate the penalty percentage that
  # a student should get
  def calculate_penalty(overtime_hours)
    return 0 if overtime_hours <= 0
    total_penalty = 0
    periods.each do |period|
      deduction = period.deduction
      if deduction < 0
        deduction = -deduction
      end
      total_penalty = total_penalty + deduction
      overtime_hours = overtime_hours - period.hours
      break if overtime_hours <= 0
    end
    total_penalty
  end

end
