module SubmissionsHelper
  include AutomatedTestsClientHelper

  def find_appropriate_grouping(assignment_id, params)
    if current_user.admin? || current_user.ta?
      Grouping.find(params[:grouping_id])
    else
      current_user.accepted_grouping_for(assignment_id)
    end
  end

  def set_pr_release_on_results(groupings, release)
    changed = 0
    groupings.each do |grouping|
      name = grouping.group.group_name

      result_prs = grouping.peer_reviews_to_others
      results = result_prs.map &:result
      results.each do |result|
        result.released_to_students = release
        unless result.save!
          raise t('marking_state.result_not_saved', group_name: name)
        end

        #TODO: no error is thrown, but result.released_to_students is suddenly false

        changed += 1
      end
    end
    changed
  end

  # Release or unrelease the submissions of a set of groupings.
  # TODO: Note that this terminates the first time an error is encountered,
  # and displays an error message to the user, even though some groupings
  # *will* have their results released. We should change this to behave
  # similar to other bulk actions, in which all errors are collected
  # and reported, but the page does refresh and successes displayed.
  def set_release_on_results(groupings, release)
    changed = 0
    groupings.each do |grouping|
      name = grouping.group.group_name

      unless grouping.has_submission?
        raise t('marking_state.no_submission', group_name: name)
      end

      unless grouping.marking_completed?
        if release
          raise t('marking_state.not_complete', group_name: name)
        else
          raise t('marking_state.not_complete_unrelease', group_name: name)
        end
      end

      result = grouping.current_submission_used.get_latest_result
      result.released_to_students = release
      unless result.save
        raise t('marking_state.result_not_saved', group_name: name)
      end

      changed += 1
    end
    changed
  end

  def get_submissions_table_info(assignment, groupings)
    if !current_user.is_a_reviewer?(assignment)
      parts = groupings.select &:has_submission?
      results = Result.where(submission_id:
                                 parts.map(&:current_submission_used))
                    .order(:id)
    end

    groupings.map.with_index do |grouping, i|
      g = Hash.new
      begin # if anything raises an error, catch it and log in the object.
        if current_user.is_a_reviewer?(assignment)
          # "groupings" are the reviewee groupings.
          # Get the respective reviewee's result from grouping
          result_pr = current_user.grouping_for(assignment.id).review_for(grouping)
          result = Result.find(result_pr.result_id)

        elsif assignment.is_peer_review? && !current_user.student?
          # if an admin is viewing reviews a grouping made
          result_pr = grouping.peer_reviews_to_others.first
          if !result_pr.nil?
            # this means they have atleast one group to review
            result = Result.find(result_pr.result_id)
          else
            # this grouping is not assigned to do any reviews
            result = nil
          end

        else
          submission = grouping.current_submission_used
          if submission.nil?
            result = nil
          elsif submission.submitted_remark.nil?
            result = (results.select do |r|
              r.submission_id == submission.id && !r.is_a_review?
            end).first
          else
            result = submission.remark_result
          end
        end

        g[:name] = grouping.get_group_name
        unless current_user.student?
          g[:id] = grouping.id
          g[:repo_name] = grouping.group.repository_name
          g[:repo_url] = repo_browser_assignment_submission_path(assignment,
                                                                 grouping)
          g[:final_grade] = grouping.final_grade(result)
          g[:tags] = grouping.tags
          g[:commit_date] = grouping.last_commit_date
          g[:has_files] = grouping.has_files_in_submission?
          g[:late_commit] =
            # TODO: Enable this check for Git backend. See issue #1866.
            if MarkusConfigurator.markus_config_repository_type == 'git'
              false
            else
              grouping.past_due_date?
            end
          g[:grace_credits_used] = grouping.grace_period_deduction_single
          g[:section] = grouping.section
        end
        if assignment.is_peer_review?
          # create a array of hashes, where each hash represents a reviewee with the reviewee grouping's
          # name and URL to view marks
          g[:reviewees] = grouping.peer_reviews_to_others.map do |pr|
            reviewee_result = pr.result
            reviewee_grouping = reviewee_result.submission.grouping
            { reviewee_url: url_for(view_marks_assignment_submission_result_path(
                                      assignment.parent_assignment,
                                      reviewee_result.submission,
                                      reviewee_result,
                                      reviewer_grouping_id: grouping.id)),
              reviewee_name: reviewee_grouping.group.group_name }
          end
        end
        g[:name_url] = assignment.is_peer_review? && current_user.is_a_reviewer?(assignment) ?
            edit_assignment_result_path(assignment.parent_assignment.id, result_pr.result_id) :
            get_grouping_name_url(grouping, result)
        g[:class_name] = get_tr_class(grouping, assignment)
        g[:state] = grouping.marking_state(result, assignment, current_user)
        g[:anonymous_id] = i + 1
        g[:error] = ''
      rescue => e
        m_logger = MarkusLogger.instance
        m_logger.log(
          "Unexpected exception #{e.message}: could not display submission " +
          "on assignment id #{grouping.group_id}. Backtrace follows:" + "\n" +
          e.backtrace.join("\n"), MarkusLogger::ERROR)
        g[:error] = e.message
      end
      g
    end
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
    elsif grouping.error_collecting
      'submission_error'
    else
      nil
    end
  end

  def get_grouping_name_url(grouping, result)
    if !grouping.peer_reviews_to_others.empty? && result.is_a_review?
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

  def get_repo_browser_table_info(assignment, revision, revision_number, path,
                                  previous_path, grouping_id)
    exit_directory = get_exit_directory(previous_path, grouping_id,
                                        revision_number, revision,
                                        assignment.repository_folder,
                                        'repo_browser')

    full_path = File.join(assignment.repository_folder, path)
    if revision.path_exists?(full_path)
      files = revision.files_at_path(full_path)
      files_info = get_files_info(files, assignment.id, revision_number, path,
                                  grouping_id)

      directories = revision.directories_at_path(full_path)
      directories_info = get_directories_info(directories, revision_number,
                                              path, grouping_id, 'repo_browser')
      return exit_directory + files_info + directories_info
    else
      return exit_directory
    end
  end

  def get_exit_directory(previous_path, grouping_id, revision_number,
                         revision, folder, action)
    full_previous_path = File.join('/', folder, previous_path)
    parent_path_of_prev_dir, prev_dir = File.split(full_previous_path)

    directories = revision.directories_at_path(parent_path_of_prev_dir)

    e = {}
    e[:id] = nil
    e[:filename] = view_context.image_tag('icons/folder.png') +
        view_context.link_to( ' ../', action: action,
                                        id: grouping_id, path: previous_path,
                                        revision_number: revision_number)
    e[:last_revised_date] = I18n.l(directories[prev_dir].last_modified_date,
                                   format: :long_date)
    e[:revision_by] = directories[prev_dir].user_id
    [e]
  end

  def get_files_info(files, assignment_id, revision_number, path, grouping_id)
    files.map do |file_name, file|
      f = {}
      f[:id] = file.object_id
      f[:filename] = view_context.image_tag('icons/page_white_text.png') +
          view_context.link_to(" #{file_name}", action: 'download',
                               id: assignment_id,
                               revision_number: revision_number,
                               file_name: file_name,
                               path: path, grouping_id: grouping_id)
      f[:raw_name] = file_name
      f[:last_revised_date] = I18n.l(file.last_modified_date,
                                     format: :long_date)
      f[:last_modified_revision] = file.last_modified_revision
      f[:revision_by] = file.user_id
      f
    end
  end

  def get_directories_info(directories, revision_number, path, grouping_id, action)
    directories.map do |directory_name, directory|
      d = {}
      d[:id] = directory.object_id
      d[:filename] = view_context.image_tag('icons/folder.png') +
          # TODO: should the call below use
          # id: assignment_id and grouping_id: grouping_id
          # like the files info?
          view_context.link_to(" #{directory_name}/",
                               action: action,
                               id: grouping_id,
                               revision_number: revision_number,
                               path: File.join(path, directory_name))
      d[:last_revised_date] = I18n.l(directory.last_modified_date,
                                     format: :long_date)
      d[:last_modified_revision] = directory.last_modified_revision
      d[:revision_by] = directory.user_id
      d
    end
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
