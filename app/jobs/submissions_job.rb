class SubmissionsJob < ApplicationJob
  def add_warning_messages(messages)
    msg = [status[:warning_message], *messages].compact.join("\n")
    status.update(warning_message: msg)
    Rails.logger.error msg
  end

  def copy_old_grading_data(new_submission, grouping)
    # at this point, it will only have one result
    new_result = new_submission.current_result

    # get the last submission that wasn't the one we just created
    old_submission = grouping.submissions.where.not(id: new_submission.id)
                             .order(created_at: :desc)
                             .first

    old_result = old_submission.non_pr_results
                               .where(remark_request_submitted_at: nil)
                               .last

    result_data = [
      { old: old_result.annotations, new: new_result.annotations },
      { old: old_result.marks, new: new_result.marks },
      { old: old_result.extra_marks, new: new_result.extra_marks }
    ]

    # copy over data from old result
    result_data.each do |result_set|
      # get rid of the existing empty records so we can replace them
      result_set[:new].destroy_all

      result_set[:old].each do |item|
        item_dup = item.dup
        item_dup.update(result_id: new_result.id)

        add_warning_messages(item_dup.errors.full_messages) if item_dup.errors.present?
      end
    end

    # copy over old test data, which are on the submission instead of the result
    old_submission.test_runs.each do |test_run|
      test_run_dup = test_run.dup
      test_run_dup.submission_id = new_submission.id
      test_run_dup.save

      # don't continue if there are errors at this point
      return add_warning_messages(test_run_dup.errors.full_messages) if test_run_dup.errors.present?

      test_run.test_group_results.each do |test_group_result|
        test_group_result_dup = test_group_result.dup
        test_group_result_dup.update(test_run_id: test_run_dup.id)

        return add_warning_messages(test_group_result_dup.errors.full_messages) if test_group_result_dup.errors.present?

        test_group_result.test_results.each do |test_result|
          test_result_dup = test_result.dup
          test_run_dup.update(test_group_result_id: test_group_result_dup.id)

          add_warning_messages(test_result_dup.errors.full_messages) if test_result_dup.errors.present?
        end
      end
    end
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

      copy_old_grading_data(new_submission, grouping) if options[:retain_existing_grading]

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
        CollectSubmissionsChannel.broadcast_to(options[:enqueuing_user], status.to_h)
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
        message = status.to_h
      end
      CollectSubmissionsChannel.broadcast_to(options[:enqueuing_user], message.merge({ update_table: true }))
    end
    m_logger.log('Submission collection process done')
  end
end
