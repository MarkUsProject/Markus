module SubmissionsHelper
  
  # Declares the rules if a user can access a submit page, 
  # given an assignment instance.
  # Also responsible for the redirects if certain rules are violated
  # Override when necessary
  def validate_submit(assignment, sub_time)
    redirect_to :action => 'index' unless assignment
    
    # check if user is allowed to submit after past due date
    rule = assignment.submission_rule  
    allowed_days_late = rule.allow_submit_until || 0
    extended_due_date = @assignment.due_date.advance(:days => allowed_days_late)
    
    unless sub_time < extended_due_date
      flash[:error] = "Deadline has passed. You cannot submit anymore at this time."
      return false
    end
       
    return true unless assignment.group_assignment?  # individual assignment
    
    # check if user has a group
    @grouping = current_user.grouping_for(assignment.id)
    if not @grouping
      flash[:error] = "You need to form a group to submit"
      return false
    end
       
    # check if user has pending status

    if @grouping.pending?(current_user)
      flash[:error] = "You need to join a group or form your own to submit."
      return false
    end
    
    # check if group has enough members to continue
    min = assignment.group_min - @grouping.memberships.count
    if min > 0
      flash[:error] = "You need to invite at least #{min} more members to submit."
      return false
    end
    
    return true
  end

  def construct_file_manager_table_row(file_name, file)
    table_row = {}
    table_row[:id] = file.id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/table_row/filter_table_row', :locals => {:file_name => file_name, :file => file}
    
    table_row[:filename] = file_name
    
    table_row[:last_modified_date] = file.last_modified_date.strftime('%d %B, %l:%M%p')

    table_row[:last_modified_date_unconverted] = file.last_modified_date

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

    table_row[:last_modified_date_unconverted] = file.last_modified_date

    table_row[:revision_by] = file.user_id

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
