module SubmissionsHelper
  def find_appropriate_grouping(assignment_id, params)
    if current_role.instructor? || current_role.ta?
      Grouping.find(params[:grouping_id])
    else
      current_role.accepted_grouping_for(assignment_id)
    end
  end

  def set_pr_release_on_results(peer_review_ids, release)
    Result.transaction do
      results = Result.joins(:peer_reviews).where('peer_reviews.id': peer_review_ids)

      without_complete_result = results.where.not(marking_state: Result::MARKING_STATES[:complete])
      if without_complete_result.present?
        group_names = without_complete_result.joins(:group).pluck(:group_name).join(', ')
        if release
          flash_now(:error, t('submissions.errors.not_complete', group_name: group_names))
        else
          flash_now(:error, t('submissions.errors.not_complete_unrelease', group_name: group_names))
        end
      end

      results.where(marking_state: Result::MARKING_STATES[:complete])
             .update_all(released_to_students: release)
    end
  end

  def get_file_info(file_name, file, course_id, assignment_id, revision_identifier,
                    path, grouping_id, url_submit: false)
    return if Repository.get_class.internal_file_names.include? file_name
    f = {}
    f[:id] = file.object_id
    f[:url] = download_course_assignment_submissions_url(
      course_id: course_id,
      assignment_id: assignment_id,
      revision_identifier: revision_identifier,
      file_name: file_name,
      path: path,
      grouping_id: grouping_id
    )
    f[:filename] =
      helpers.image_tag('icons/page_white_text.png') +
      helpers.link_to(" #{file_name}",
                      download_course_assignment_submissions_path(
                        course_id,
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
    file_type = FileHelper.get_file_type(file_name)
    f[:type] = file_type == 'markusurl' && !url_submit ? 'unknown' : file_type
    f
  end
end
