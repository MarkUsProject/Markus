module SubmissionsHelper

  def find_appropriate_grouping(assignment_id, params)
    if current_user.admin? || current_user.ta?
      return Grouping.find(params[:grouping_id])
    else
      return current_user.accepted_grouping_for(assignment_id)
    end
  end

  def set_release_on_results(groupings, release, errors)
    changed = 0
    groupings.each do |grouping|
      begin
        raise I18n.t("marking_state.no_submission", :group_name => grouping.group_name) if !grouping.has_submission?
        submission = grouping.current_submission_used
        raise I18n.t("marking_state.no_result", :group_name => grouping.group.group_name) if !submission.has_result?
        raise I18n.t("marking_state.not_complete", :group_name => grouping.group.group_name) if submission.get_latest_result.marking_state != Result::MARKING_STATES[:complete]
        @result = submission.get_latest_result
        @result.released_to_students = release
        if !@result.save
          raise I18n.t("marking_state.result_not_saved", :group_name => grouping.group.group_name)
        end
        changed += 1
      rescue Exception => e
        errors.push(e.message)
      end
    end
    return changed
  end

  def construct_file_manager_dir_table_row(directory_name, directory)
    table_row = {}
    table_row[:id] = directory.object_id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/table_row/directory_table_row', :locals => {:directory_name => directory_name, :directory => directory}
    table_row[:filename] = directory_name
    table_row[:last_modified_date_unconverted] = directory.last_modified_date.strftime('%b %d, %Y %H:%M')
    table_row[:revision_by] = directory.user_id
    return table_row

  end

  def construct_file_manager_table_row(file_name, file)
    table_row = {}
    table_row[:id] = file.object_id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/table_row/filter_table_row', :locals => {:file_name => file_name, :file => file}

    table_row[:filename] = file_name

    table_row[:last_modified_date] = file.last_modified_date.strftime('%d %B, %l:%M%p')

    table_row[:last_modified_date_unconverted] = file.last_modified_date.strftime('%b %d, %Y %H:%M')

    table_row[:revision_by] = file.user_id

    return table_row
  end


  def construct_file_manager_table_rows(files)
    result = {}
    files.each do |file_name, file|
      result[file.object_id] = construct_file_manager_table_row(file_name, file)
    end
    return result
  end

  def construct_repo_browser_table_row(file_name, file)
    table_row = {}
    table_row[:id] = file.object_id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/repo_browser/filter_table_row', :locals => {:file_name => file_name, :file => file}
    table_row[:filename] = file_name
    table_row[:last_modified_date] = file.last_modified_date.strftime('%d %B, %l:%M%p')
    table_row[:last_modified_date_unconverted] = file.last_modified_date.strftime('%b %d, %Y %H:%M')
    table_row[:revision_by] = file.user_id
    return table_row
  end

  def construct_repo_browser_directory_table_row(directory_name, directory)
    table_row = {}
    table_row[:id] = directory.object_id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/repo_browser/directory_row', :locals => {:directory_name => directory_name, :directory => directory}
    table_row[:filename] = directory_name
    table_row[:last_modified_date] = directory.last_modified_date.strftime('%d %B, %l:%M%p')
    table_row[:last_modified_date_unconverted] = directory.last_modified_date.strftime('%b %d, %Y %H:%M')
    table_row[:revision_by] = directory.user_id
    return table_row
  end

  def construct_repo_browser_table_rows(files)
    result = {}
    files.each do |file_name, file|
      result[file.object_id] = construct_repo_browser_row(file_name, file)
    end
    return result
  end


  def sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return "" if file_name.nil?
    return File.basename(file_name).gsub(
                  SubmissionFile::FILENAME_SANITIZATION_REGEXP,
                  SubmissionFile::SUBSTITUTION_CHAR)
  end


  # Helper methods to determine remark request status on a submission
  def remark_in_progress(submission)
    return (submission.get_remark_result and submission.get_remark_result.marking_state == Result::MARKING_STATES[:partial])
  end

  def remark_complete_but_unreleased(submission)
    return (submission.get_remark_result and submission.get_remark_result.marking_state == Result::MARKING_STATES[:complete] and !submission.get_remark_result.released_to_students)
  end

end
