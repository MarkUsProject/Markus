class SubmissionsJob < ApplicationJob
  def self.on_complete_js(_status)
    'window.submissionTable.wrapped.fetchData'
  end

  def self.show_status(status)
    I18n.t('poll_job.submissions_job', progress: status[:progress], total: status[:total])
  end

  def add_error_messages(messages)
    msg = [status[:error_message], *messages].compact.join("\n")
    status.update(error_message: msg)
    Rails.logger.error msg
  end

  def perform(groupings, options = {})
    return if groupings.empty?

    m_logger = MarkusLogger.instance
    assignment = groupings.first.assignment

    progress.total = groupings.size
    groupings.each do |grouping|
      m_logger.log("Now collecting: #{assignment.short_identifier} for grouping: " +
                   grouping.id.to_s)
      if options[:revision_identifier].nil?
        time = if assignment.scanned_exam?
                 Time.current
               else
                 options[:collection_dates]&.fetch(grouping.id, nil) || grouping.collection_date
               end
        new_submission = Submission.create_by_timestamp(grouping, time)
      else
        new_submission = Submission.create_by_revision_identifier(grouping, options[:revision_identifier])
      end

      if assignment.submission_rule.is_a? GracePeriodSubmissionRule
        # Return any grace credits previously deducted for this grouping.
        assignment.submission_rule.remove_deductions(grouping)
      end

      if options[:apply_late_penalty].nil? || options[:apply_late_penalty]
        assignment.submission_rule.apply_submission_rule(new_submission)
      end

      grouping.is_collected = true
      grouping.save
      add_error_messages(grouping.errors.full_messages) if grouping.errors.present?
      progress.increment
    rescue StandardError => e
      add_error_messages([e.message])
    end
  ensure
    m_logger.log('Submission collection process done')
  end
end
