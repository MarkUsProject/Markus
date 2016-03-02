module SubmissionsHelper
  def find_appropriate_grouping(assignment_id, params)
    if current_user.admin? || current_user.ta?
      Grouping.find(params[:grouping_id])
    else
      current_user.accepted_grouping_for(assignment_id)
    end
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
    parts = groupings.select &:has_submission?
    results = Result.where(submission_id:
                             parts.map(&:current_submission_used))
                    .order(:id)
    groupings.map do |grouping|
      g = Hash.new
      begin # if anything raises an error, catch it and log in the object.
        submission = grouping.current_submission_used
        if submission.nil?
          result = nil
        elsif !submission.remark_submitted?
          result = (results.select do |r|
            r.submission_id == submission.id
          end).first
        else
          result = (results.select do |r|
            r.id == submission.remark_result_id
          end).first
        end
        final_due_date = assignment.submission_rule.get_collection_time
        g[:name] = grouping.get_group_name
        g[:id] = grouping.id
        g[:section] = grouping.section
        g[:tags] = grouping.tags
        g[:commit_date] = grouping.last_commit_date
        g[:has_files] = grouping.has_files_in_submission?
        g[:late_commit] = grouping.past_due_date?
        g[:name_url] = get_grouping_name_url(grouping, final_due_date, result)
        g[:class_name] = get_tr_class(grouping)
        g[:grace_credits_used] = grouping.grace_period_deduction_single
        g[:repo_name] = grouping.group.repository_name
        g[:repo_url] = repo_browser_assignment_submission_path(assignment,
                                                               grouping)
        g[:final_grade] = grouping.final_grade(result)
        g[:state] = grouping.marking_state(result)
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
  def get_tr_class(grouping)
    if grouping.is_collected?
      'submission_collected'
    elsif grouping.error_collecting
      'submission_error'
    else
      nil
    end
  end

  def get_grouping_name_url(grouping, final_due_date, result)
    assignment = grouping.assignment
    if grouping.is_collected?
      url_for(edit_assignment_submission_result_path(
                assignment, grouping, result))
    elsif grouping.has_submission? ||
          (grouping.inviter.section.nil? && Time.zone.now > final_due_date) ||
          assignment.submission_rule.can_collect_grouping_now?(grouping)
      url_for(collect_and_begin_grading_assignment_submission_path(
                assignment, grouping))
    else
      ''
    end
  end

  # Collects submissions for all the groupings of the given section and assignment
  # Return the number of actually collected submissions
  def collect_submissions_for_section(section_id, assignment, errors)

    collected = 0

    begin

      raise I18n.t('collect_submissions.could_not_find_section') if !Section.exists?(section_id)
      section = Section.find(section_id)

      # Check collection date
      if Time.zone.now < SectionDueDate.due_date_for(section, assignment)
        raise I18n.t('collect_submissions.could_not_collect_section',
          assignment_identifier: assignment.short_identifier,
          section_name: section.name)
      end

      # Collect and count submissions for all groupings of this section
      groupings = Grouping.where(assignment_id: assignment.id)
      submission_collector = SubmissionCollector.instance
      groupings.each do |grouping|
        if grouping.section == section.name
          submission_collector.push_grouping_to_priority_queue(grouping)
          collected += 1
        end
      end

      if collected == 0
        raise I18n.t('collect_submissions.no_submission_for_section',
          section_name: section.name)
      end

    rescue Exception => e
      errors.push(e.message)
    end

    collected

  end

  def get_repo_browser_table_info(assignment, revision, revision_number, path,
                                  previous_path, grouping_id)
    exit_directory = get_exit_directory(previous_path, grouping_id,
                                        revision_number, revision,
                                        assignment.repository_folder)

    full_path = File.join(assignment.repository_folder, path)
    if revision.path_exists?(full_path)
      files = revision.files_at_path(full_path)
      files_info = get_files_info(files, assignment.id, revision_number, path,
                                  grouping_id)

      directories = revision.directories_at_path(full_path)
      directories_info = get_directories_info(directories, revision_number,
                                              path, grouping_id)
      return exit_directory + files_info + directories_info
    else
      return exit_directory
    end
  end

  def get_exit_directory(previous_path, grouping_id, revision_number,
                         revision, folder)
    full_previous_path = File.join('/', folder, previous_path)
    parent_path_of_prev_dir, prev_dir = File.split(full_previous_path)

    directories = revision.directories_at_path(parent_path_of_prev_dir)

    e = {}
    e[:id] = nil
    e[:filename] = view_context.link_to '../', action: 'repo_browser',
                                        id: grouping_id, path: previous_path,
                                        revision_number: revision_number
    e[:last_revised_date] = directories[prev_dir].last_modified_date
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

  def get_directories_info(directories, revision_number, path, grouping_id)
    directories.map do |directory_name, directory|
      d = {}
      d[:id] = directory.object_id
      d[:filename] = view_context.image_tag('icons/folder.png') +
          # TODO: should the call below use
          # id: assignment_id and grouping_id: grouping_id
          # like the files info?
          view_context.link_to(" #{directory_name}/",
                               action: 'repo_browser',
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
      submission.remark_result.marking_state == Result::MARKING_STATES[:partial]
  end

  def remark_complete_but_unreleased(submission)
    submission.remark_result &&
      (submission.remark_result.marking_state ==
         Result::MARKING_STATES[:complete]) &&
        !submission.remark_result.released_to_students
  end

  # Checks if all the assignments for the current submission are marked.
  def all_assignments_marked?
    Assignment.includes(groupings: [:current_submission_used])
              .find(params[:assignment_id])
              .groupings.all?(&:marking_completed?)
  end

end
