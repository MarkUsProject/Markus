class PenaltyDecayPeriodSubmissionRule < SubmissionRule
  # This message will be dislayed to Students on viewing their file manager
  # after the due date has passed, but before the calculated collection date.
  def overtime_message(grouping)
    # How far are we into overtime?
    overtime_hours = calculate_overtime_hours_from(Time.current, grouping)
    # Calculate the penalty that the grouping will suffer
    potential_penalty = calculate_penalty(overtime_hours)

    I18n.t 'penalty_decay_period_submission_rules.overtime_message', potential_penalty: potential_penalty
  end

  def apply_submission_rule(submission)
    # Calculate the appropriate penalty, and attach the ExtraMark to the
    # submission Result
    return submission if submission.is_empty
    result = submission.get_original_result
    unit = self.penalty_type || ExtraMark::PERCENTAGE
    overtime_hours = calculate_overtime_hours_from(submission.revision_timestamp, submission.grouping)
    penalty_amount = calculate_penalty(overtime_hours)
    if penalty_amount.positive?
      ExtraMark.create(result: result,
                       extra_mark: -penalty_amount,
                       unit: unit,
                       description: I18n.t('penalty_decay_period_submission_rules.extramark_description',
                                           overtime_hours: overtime_hours.round(2), penalty_amount: penalty_amount))
    end

    submission
  end

  def hours_sum
    periods.sum('hours')
  end

  # Given a number of overtime_hours, calculate the penalty percentage that
  # a student should get
  def calculate_penalty(overtime_hours)
    total_penalty = 0
    periods.each do |period|
      break if overtime_hours <= 0
      deduction = period.deduction || 0
      if deduction < 0
        deduction = -deduction
      end

      num_intervals =
        ([overtime_hours, period.hours].min / period.interval).ceil.to_f
      total_penalty += num_intervals * deduction
      overtime_hours -= period.hours
    end
    total_penalty
  end
end
