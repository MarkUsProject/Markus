module SubmissionsHelper
  
  def find_appropriate_grouping(assignment_id, params)
    if current_user.admin? || current_user.ta?
      return Grouping.find(params[:grouping_id])
    else
      return current_user.accepted_grouping_for(assignment_id)
    end
  end
  
  def construct_file_manager_dir_table_row(directory_name, directory)
    table_row = {}
    table_row[:id] = directory.id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/table_row/directory_table_row', :locals => {:directory_name => directory_name, :directory => directory}
    table_row[:filename] = directory_name
    table_row[:last_modified_date_unconverted] = directory.last_modified_date.strftime('%b %d, %Y %H:%M')
    table_row[:revision_by] = directory.user_id
    return table_row
    
  end
  
  def construct_file_manager_table_row(file_name, file)
    table_row = {}
    table_row[:id] = file.id
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
      result[file.id] = construct_file_manager_table_row(file_name, file)
    end
    return result
  end
  
  
 def construct_submissions_table_row(grouping, assignment)
    table_row = {}
    table_row[:id] = grouping.id
   table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/submissions_table_row/filter_table_row', :locals => {:grouping => grouping, :assignment => assignment}
    
    table_row[:group_name] = grouping.group.group_name
  
    table_row[:repository] = grouping.group.repository_name

    if !@details.nil?
      assignment.rubric_criteria.each_with_index do |criterion, index|
        if grouping.has_submission?
          mark = grouping.get_submission_used.result.marks.find_by_rubric_criterion_id(criterion.id)
          if mark.nil? || mark.mark.nil?
            table_row['criterion_' + index.to_s] = '0'
          else
            table_row['criterion_' + index.to_s] = mark.mark
          end
        else
          table_row['criterion_' + index.to_s] = '0'
        end
      end
    end

    if grouping.has_submission?
      table_row[:marking_state] = grouping.get_submission_used.result.marking_state
      table_row[:final_grade] = grouping.get_submission_used.result.total_mark
      table_row[:released] = grouping.get_submission_used.result.released_to_students
      table_row[:commit_date] = grouping.get_submission_used.revision_timestamp.strftime(LONG_DATE_TIME_FORMAT)
    else
      table_row[:marking_state] = '-'
      table_row[:final_grade] = '-'
      table_row[:released] = '-'
      table_row[:commit_date] = '-'
    end

    return table_row
  end

  def construct_repo_browser_table_row(file_name, file)
    table_row = {}
    table_row[:id] = file.id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/repo_browser/filter_table_row', :locals => {:file_name => file_name, :file => file}
    table_row[:filename] = file_name
    table_row[:last_modified_date] = file.last_modified_date.strftime('%d %B, %l:%M%p')
    table_row[:last_modified_date_unconverted] = file.last_modified_date.strftime('%b %d, %Y %H:%M')
    table_row[:revision_by] = file.user_id
    return table_row
  end

  def construct_repo_browser_directory_table_row(directory_name, directory)
    table_row = {}
    table_row[:id] = directory.id
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
      result[file.id] = construct_repo_browser_row(file_name, file)
    end
    return result
  end

  def construct_submissions_table_rows(groupings)
    result = {}
    groupings.each do |grouping|
      result[grouping.id] = construct_submissions_table_row(grouping)
    end
    return result
  end
  
  def sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return "" if file_name.nil?
    return File.basename(file_name).gsub(/[^\w\.\-]/, '_')
  end
  
end
