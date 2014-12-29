module SubmissionsHelper
  # Gets relevant groupings for assignment based on
  # user type (ta or admin)
  def get_groupings_for_assignment(assignment, user)
    if user.ta?
      assignment.ta_memberships.find_all_by_user_id(current_user)
        .select { |m| m.grouping.is_valid? }
        .map { |m| m.grouping }
    else
      assignment.groupings
        .includes(:assignment,
                  :group,
                  :grace_period_deductions,
                  current_submission_used: :results,
                  accepted_student_memberships: :user)
        .select { |g| g.non_rejected_student_memberships.size > 0 }
    end
  end

  def find_appropriate_grouping(assignment_id, params)
    if current_user.admin? || current_user.ta?
      Grouping.find(params[:grouping_id])
    else
      current_user.accepted_grouping_for(assignment_id)
    end
  end

  def set_release_on_results(groupings, release)
    changed = 0
    groupings.each do |grouping|
      raise I18n.t('marking_state.no_submission',
                   group_name: grouping.group.group_name) unless grouping.has_submission?
      submission = grouping.current_submission_used
      raise I18n.t('marking_state.no_result',
                   group_name: grouping.group.group_name) unless submission.has_result?
      raise I18n.t('marking_state.not_complete', group_name: grouping.group.group_name) if
        submission.get_latest_result.marking_state != Result::MARKING_STATES[:complete] && release
      raise I18n.t('marking_state.not_complete_unrelease', group_name: grouping.group.group_name) if
        submission.get_latest_result.marking_state != Result::MARKING_STATES[:complete]
      result = submission.get_latest_result
      result.released_to_students = release
      unless result.save
        raise I18n.t('marking_state.result_not_saved', group_name: grouping.group.group_name)
      end
      changed += 1
    end
    changed
  end

  def get_submissions_table_info(assignment, groupings)
    groupings.map do |grouping|
      g = grouping.attributes
      g[:class_name] = get_any_tr_attributes(grouping)
      g[:group_name] = get_grouping_group_name(assignment, grouping)
      g[:repository] = get_grouping_repository(assignment, grouping)
      begin
        g[:commit_date] = get_grouping_commit_date(grouping)
      rescue NoMethodError
        g[:commit_date] = 'Uh oh! Assignment folder missing.'
      rescue RuntimeError
        g[:commit_date] = 'Uh oh! No repo found for this group.'
      end
      g[:marking_state] = get_grouping_marking_state(assignment, grouping)
      g[:grace_credits_used] = get_grouping_grace_credits_used(grouping)
      g[:final_grade] = get_grouping_final_grades(grouping)
      g[:can_begin_grading] =
          get_grouping_can_begin_grading(assignment, grouping)
      g[:state] = get_grouping_state(grouping)
      g[:section] = get_grouping_section(grouping)
      g[:tags] = get_grouping_tags(grouping)
      g
    end
  end

  # If the grouping is collected or has an error, 
  # style the table row green or red respectively.
  # Classname will be applied to the table row
  # and actually styled in CSS.
  def get_any_tr_attributes(grouping)
    if grouping.is_collected?
      return 'submission_collected'
    elsif grouping.error_collecting
      return 'submission_error'
    else
      return nil
    end
  end

  def get_grouping_tags(grouping)
    grouping.tags
  end

  def get_grouping_group_name(assignment, grouping)
    group_name = ''
      if !grouping.has_submission?
        if assignment.submission_rule.can_collect_grouping_now?(grouping)
          group_name = view_context.link_to(grouping.group.group_name,
            collect_and_begin_grading_assignment_submission_path(
              assignment.id, grouping.id))
        else
          group_name = grouping.group.group_name
        end
      elsif !grouping.is_collected
        group_name = view_context.link_to(grouping.group.group_name,
          collect_and_begin_grading_assignment_submission_path(
            assignment.id, grouping.id))
      else
        group_name = view_context.link_to(grouping.group.group_name,
          edit_assignment_submission_result_path(
            assignment.id, grouping.current_submission_used.id,
            grouping.current_submission_used.get_latest_result))
      end

      group_name += ' ('
      group_name += grouping.accepted_students.collect{ |student| student.user_name}.join(', ')
      group_name += ')'
      return group_name
  end

  def get_grouping_section(grouping)
    return grouping.section
  end

  def get_grouping_repository(assignment, grouping)
    view_context.link_to(grouping.group.repository_name,
      repo_browser_assignment_submission_path(assignment, grouping))
  end

  def get_grouping_commit_date(grouping)
    if !grouping.has_submission?
      return '-'
    else
      commit_date = ''
      if grouping.past_due_date?
        commit_date += view_context.image_tag('icons/error.png',
            title: t(:past_due_date_edit_result_warning,
            href: t(:last_commit)))
      end
      commit_date += I18n.l(grouping.current_submission_used.revision_timestamp,
                            format: :long_date)
      return commit_date
    end
  end

  def get_grouping_marking_state(assignment, grouping)
    if !grouping.has_submission?
      if assignment.submission_rule.can_collect_now?
        return view_context.image_tag('icons/shape_square.png',
          alt: I18n.t('marking_state.not_collected'),
          title: I18n.t('marking_state.not_collected'))
      else
        return '-'
      end
    else
      if !grouping.current_submission_used.has_result?
        return view_context.image_tag('icons/pencil.png',
          alt: I18n.t('marking_state.in_progress'),
          title: I18n.t('marking_state.in_progress'))
      else
        if remark_in_progress(grouping.current_submission_used)
          return view_context.image_tag('icons/double_exclamation.png',
            alt: I18n.t('marking_state.remark_requested'),
            title: I18n.t('marking_state.remark_requested'))
        elsif grouping.current_submission_used.get_latest_result.marking_state == Result::MARKING_STATES[:complete]
          if !grouping.current_submission_used.get_latest_result.released_to_students
            return view_context.image_tag('icons/accept.png',
              alt: I18n.t('marking_state.completed'),
              title: I18n.t('marking_state.completed'))
          else
            return view_context.image_tag('icons/email_go.png',
              alt: I18n.t('marking_state.released'),
              title: I18n.t('marking_state.released'))
          end
        else
          return view_context.image_tag('icons/pencil.png',
            alt: I18n.t('marking_state.in_progress'),
            title: I18n.t('marking_state.in_progress'))
        end
      end
    end
  end

  def get_grouping_state(grouping)
    if !grouping.has_submission? || !grouping.current_submission_used.has_result?
      'unmarked'
    elsif grouping.current_submission_used.get_latest_result.marking_state != Result::MARKING_STATES[:complete]
      'partial'
    elsif grouping.current_submission_used.get_latest_result.released_to_students
      'released'
    else
      'complete'
    end
  end

  def get_grouping_grace_credits_used(grouping)
    grouping.grace_period_deduction_single
  end

  def get_grouping_final_grades(grouping)
    case get_grouping_state(grouping)
    when 'unmarked'
      '-'
    when 'partial'
      '-'
    when 'complete'
      grouping.current_submission_used.get_latest_result.total_mark
    when 'released'
      grouping.current_submission_used.get_latest_result.total_mark
    end
  end

  def get_grouping_can_begin_grading(assignment, grouping)
    if assignment.submission_rule.can_collect_grouping_now?(grouping)
      return view_context.image_tag('icons/tick.png')
    else
      return view_context.image_tag('icons/cross.png')
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
      groupings = Grouping.find_all_by_assignment_id(assignment.id)
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


  def construct_file_manager_dir_table_row(directory_name, directory)
    table_row = {}
    table_row[:id] = directory.object_id
    table_row[:filter_table_row_contents] = render_to_string partial: 'submissions/table_row/directory_table_row', locals: {directory_name: directory_name, directory: directory}
    table_row[:filename] = directory_name
    table_row[:last_modified_date_unconverted] = directory.last_modified_date.strftime('%b %d, %Y %H:%M')
    table_row[:revision_by] = directory.user_id
    table_row

  end

  def construct_file_manager_table_row(file_name, file)
    table_row = {}
    table_row[:id] = file.object_id
    table_row[:filter_table_row_contents] = render_to_string partial: 'submissions/table_row/filter_table_row', locals: {file_name: file_name, file: file}

    table_row[:filename] = file_name

    table_row[:last_modified_date] = file.last_modified_date.strftime('%d %B, %l:%M%p')

    table_row[:last_modified_date_unconverted] = file.last_modified_date.strftime('%b %d, %Y %H:%M')

    table_row[:revision_by] = file.user_id

    table_row
  end


  def construct_file_manager_table_rows(files)
    result = {}
    files.each do |file_name, file|
      result[file.object_id] = construct_file_manager_table_row(file_name, file)
    end
    result
  end

  def get_repo_browser_table_info(assignment, revision, revision_number, path,
                                  previous_path, grouping_id)
    exit_directory = get_exit_directory(previous_path, grouping_id,
                                        revision_number)

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

  def get_exit_directory(previous_path, grouping_id, revision_number)
    e = {}
    e[:id] = nil
    e[:filename] = view_context.link_to '../', action: 'repo_browser',
                                        id: grouping_id, path: previous_path,
                                        revision_number: revision_number
    e[:last_revised_date] = ''
    e[:revision_by] = ''
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
      f[:last_revised_date] = I18n.l(file.last_modified_date,
                                     format: :long_date)
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
    submission.get_remark_result and submission.get_remark_result.marking_state == Result::MARKING_STATES[:partial]
  end

  def remark_complete_but_unreleased(submission)
    submission.get_remark_result and submission.get_remark_result.marking_state == Result::MARKING_STATES[:complete] and !submission.get_remark_result.released_to_students
  end

end
