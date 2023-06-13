class SubmissionsJob < ApplicationJob
  def add_warning_messages(messages)
    msg = [status[:warning_message], *messages].compact.join("\n")
    status.update(warning_message: msg)
    Rails.logger.error msg
  end

  def perform(groupings, apply_late_penalty: true, **options)
    return if groupings.empty?

    m_logger = MarkusLogger.instance
    assignment = groupings.first.assignment

    progress.total = groupings.size
    groupings.each do |grouping|
      m_logger.log("Now collecting: #{assignment.short_identifier} for grouping: " +
                   grouping.id.to_s)
      if options[:revision_identifier].nil?
        time = if assignment.scanned_exam? || options[:collect_current]
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

      if apply_late_penalty
        assignment.submission_rule.apply_submission_rule(new_submission)
      end

      grouping.is_collected = true
      grouping.save
      add_warning_messages(grouping.errors.full_messages) if grouping.errors.present?
      progress.increment
      unless options[:notify_socket].nil? || options[:enqueuing_user].nil?
        CollectSubmissionsChannel.broadcast_to(options[:enqueuing_user], ActiveJob::Status.get(job_id).to_h)
      end
    end
  rescue StandardError => e
    status.catch_exception(e)
    raise e
  ensure
    unless options[:notify_socket].nil? || options[:enqueuing_user].nil?
      if status&.progress == 1
        if status[:warning_message].nil?
          message = { status: :completed }
        else
          message = { status: :completed, warning_message:
            status[:warning_message] }
        end
      else
        message = ActiveJob::Status.get(job_id).to_h
      end
      CollectSubmissionsChannel.broadcast_to(options[:enqueuing_user], message.merge({ update_table: true }))
    end
    m_logger.log('Submission collection process done')
  end
end
