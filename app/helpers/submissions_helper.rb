module SubmissionsHelper

  def find_appropriate_grouping(assignment_id, params)
    if current_user.admin? || current_user.ta?
      Grouping.find(params[:grouping_id])
    else
      current_user.accepted_grouping_for(assignment_id)
    end
  end

  def set_pr_release_on_results(groupings, release)
    Result.transaction do
      Result.where(id: groupings.joins(peer_reviews_to_others: :result).pluck('results.id'))
            .update_all(released_to_students: release)
    end
  end

  # Release or unrelease the submissions of a set of groupings.
  def set_release_on_results(groupings, release)
    result = Result.transaction do
      without_submissions = groupings.where.not(id: groupings.joins(:current_submission_used))

      if without_submissions.present?
        group_names = without_submissions.joins(:group).pluck(:group_name).join(', ')
        raise I18n.t('submissions.errors.no_submission', group_name: group_names)
      end

      without_complete_result = groupings.joins(:current_result)
                                         .where.not('results.marking_state': Result::MARKING_STATES[:complete])

      if without_complete_result.present?
        group_names = without_complete_result.joins(:group).pluck(:group_name).join(', ')
        raise t('submissions.errors.not_complete', group_name: group_names) if release

        raise t('submissions.errors.not_complete_unrelease', group_name: group_names)
      end

      Result.where(id: groupings.joins(:current_result).pluck('results.id'))
            .update_all(released_to_students: release)
    end

    if release
      groupings.includes(:accepted_students).each do |grouping|
        grouping.accepted_students.each do |student|
          if student.receives_results_emails?
            NotificationMailer.with(user: student, grouping: grouping).release_email.deliver_later
          end
        end
      end
    end

    result
  end

  # If the grouping is collected or has an error,
  # style the table row green or red respectively.
  # Classname will be applied to the table row
  # and actually styled in CSS.
  def get_tr_class(grouping, assignment)
    if assignment.is_peer_review?
      nil
    elsif grouping.is_collected?
      'submission_collected'
    else
      nil
    end
  end

  def get_grouping_name_url(grouping, result)
    if grouping.assignment.is_peer_review? && !grouping.peer_reviews_to_others.empty? && result.is_a_review?
      url_for(view_marks_assignment_submission_result_path(
                  assignment_id: grouping.assignment.parent_assignment.id, submission_id: result.submission.id,
                  id: result.id, reviewer_grouping_id: grouping.id))
    elsif grouping.is_collected?
      url_for(edit_assignment_submission_result_path(
                  grouping.assignment, result.submission_id, result))
    else
      ''
    end
  end

  #TODO: Add a route in routes.rb and method mark_peer_review in the peer_reviews controller
  def get_url_peer(grouping, id)
    if grouping.is_collected?
      url_for(controller: 'peer_reviews', action: 'mark_peer_review', peer_review_id: id)
    else
      ''
    end
  end

  def get_file_info(file_name, file, assignment_id, revision_identifier, path, grouping_id)
    return if Repository.get_class.internal_file_names.include? file_name
    f = {}
    f[:id] = file.object_id
    f[:url] = download_assignment_submissions_url(
      id: assignment_id,
      revision_identifier: revision_identifier,
      file_name: file_name,
      path: path,
      grouping_id: grouping_id
    )
    f[:filename] = view_context.image_tag('icons/page_white_text.png') +
                   view_context.link_to(" #{file_name}", action: 'download',
                                                         id: assignment_id,
                                                         revision_identifier: revision_identifier,
                                                         file_name: file_name,
                                                         path: path, grouping_id: grouping_id)
    f[:raw_name] = file_name
    f[:last_revised_date] = I18n.l(file.last_modified_date)
    f[:last_modified_revision] = revision_identifier
    f[:revision_by] = file.user_id
    f[:submitted_date] = I18n.l(file.submitted_date)
    f[:type] = SubmissionFile.get_file_type(file_name)
    f
  end

  def sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return '' if file_name.nil?
    File.basename(file_name).gsub(
        SubmissionFile::FILENAME_SANITIZATION_REGEXP,
        SubmissionFile::SUBSTITUTION_CHAR)
  end

  # Helper methods to determine remark request status on a submission
  def remark_in_progress(submission)
    submission.remark_result &&
      submission.remark_result.marking_state == Result::MARKING_STATES[:incomplete]
  end

  def remark_complete_but_unreleased(submission)
    submission.remark_result &&
      (submission.remark_result.marking_state ==
         Result::MARKING_STATES[:complete]) &&
        !submission.remark_result.released_to_students
  end
end
