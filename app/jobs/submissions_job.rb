class SubmissionsJob < ActiveJob::Base
  queue_as :submissions

   before_enqueue do |_job|
      job_messenger = JobMessenger.create(job_id: job_id, status: :queued)
      PopulateCache.populate_for_job(job_messenger, job_id)
    end

  def perform(assignment, apply_late_penalty=true)

    m_logger = MarkusLogger.instance

      begin
      
        job_messenger = JobMessenger.where(job_id: job_id).first
        job_messenger.update_attributes(status: :running)
        PopulateCache.populate_for_job(job_messenger, job_id)
        m_logger.log('Submission collection process established database' +
                     ' connection successfully')		  

        assignment.groupings.each do |grouping|
        
			return if grouping.nil?
			m_logger = MarkusLogger.instance
			m_logger.log("Now collecting: #{assignment.short_identifier} for grouping: " +
						 "'#{grouping.id}'")
			time = assignment.submission_rule.calculate_collection_time.localtime
			# Create a new Submission by timestamp.
			# A Result is automatically attached to this Submission, thanks to some
			# callback logic inside the Submission model
			new_submission = Submission.create_by_timestamp(grouping, time)

      # Apply the SubmissionRule
      if apply_late_penalty
			  new_submission = assignment.submission_rule.apply_submission_rule(
			    new_submission)
      end

			unless grouping.error_collecting
			  grouping.is_collected = true
			end

			grouping.save

        end
        m_logger.log('Submission collection process done')
        assignment.done!('true')

        # Request a test run for the grouping
        request_a_test_run(grouping, new_submission)
        
	  rescue => e
		Rails.logger.error e.message
		job_messenger.update_attributes(status: failed, message: e.message)
		PopulateCache.populate_for_job(job_messenger, job_id)
		raise e
        
       job_messenger.update_attributes(status: :succeeded)
       PopulateCache.populate_for_job(job_messenger, job_id)
      end
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

  def request_a_test_run(grouping, new_submission)
    m_logger = MarkusLogger.instance
    if grouping.assignment.enable_test
      m_logger.log("Now requesting test run for #{grouping.assignment.short_identifier} \
                    on grouping: '#{grouping.id}'")
      AutomatedTestsHelper.request_a_test_run(new_submission.grouping.id,
                                              'collection',
                                              @current_user,
                                              new_submission.id)
    end
  end

end
