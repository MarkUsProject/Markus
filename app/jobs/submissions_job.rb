class SubmissionsJob < ActiveJob::Base
  queue_as :submissions

  def perform #(ids, all=false)

    m_logger = MarkusLogger.instance

      begin
        m_logger.log('Submission collection process established database' +
                     ' connection successfully')

		#if all?
		  

        Grouping.find_each do |grouping|
        
			return if grouping.nil?
			assignment = grouping.assignment
			m_logger = MarkusLogger.instance
			m_logger.log("Now collecting: #{assignment.short_identifier} for grouping: " +
						 "'#{grouping.id}'")
			time = assignment.submission_rule.calculate_collection_time.localtime
			# Create a new Submission by timestamp.
			# A Result is automatically attached to this Submission, thanks to some
			# callback logic inside the Submission model
			new_submission = Submission.create_by_timestamp(grouping, time)
			# Apply the SubmissionRule
			new_submission = assignment.submission_rule.apply_submission_rule(
			  new_submission)

			unless grouping.error_collecting
			  grouping.is_collected = true
			end

			grouping.save

        end
        m_logger.log('Submission collection process done')
      self.save
  end

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

end
