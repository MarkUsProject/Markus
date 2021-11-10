module SubmissionsHelper

  def find_appropriate_grouping(assignment_id, params)
    if current_role.admin? || current_role.ta?
      Grouping.find(params[:grouping_id])
    else
      current_role.accepted_grouping_for(assignment_id)
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
    without_submissions = groupings.where.not(id: groupings.joins(:current_submission_used))

    if without_submissions.present?
      group_names = without_submissions.joins(:group).pluck(:group_name).join(', ')
      flash_now(:error, I18n.t('submissions.errors.no_submission', group_name: group_names))
      groupings = groupings.where.not(id: without_submissions.ids)
    end

    without_complete_result = groupings.joins(:current_result)
                                       .where.not('results.marking_state': Result::MARKING_STATES[:complete])

    if without_complete_result.present?
      group_names = without_complete_result.joins(:group).pluck(:group_name).join(', ')
      if release
        flash_now(:error, t('submissions.errors.not_complete', group_name: group_names))
      else
        flash_now(:error, t('submissions.errors.not_complete_unrelease', group_name: group_names))
      end
      groupings = groupings.where.not(id: without_complete_result.ids)
    end

    result = Result.where(id: groupings.joins(:current_result).pluck('results.id'))
                   .update_all(released_to_students: release)

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

  def get_file_info(file_name, file, assignment_id, revision_identifier, path, grouping_id)
    return if Repository.get_class.internal_file_names.include? file_name
    f = {}
    f[:id] = file.object_id
    f[:url] = download_assignment_submissions_url(
      assignment_id: assignment_id,
      revision_identifier: revision_identifier,
      file_name: file_name,
      path: path,
      grouping_id: grouping_id
    )
    f[:filename] =
      helpers.image_tag('icons/page_white_text.png') +
      helpers.link_to(" #{file_name}",
                      download_assignment_submissions_path(
                        assignment_id: assignment_id,
                        revision_identifier: revision_identifier,
                        file_name: file_name,
                        path: path, grouping_id: grouping_id
                      ))
    f[:raw_name] = file_name
    f[:last_revised_date] = I18n.l(file.last_modified_date)
    f[:last_modified_revision] = revision_identifier
    f[:revision_by] = file.user_id
    f[:submitted_date] = I18n.l(file.submitted_date)
    f[:type] = FileHelper.get_file_type(file_name)
    f
  end
end
