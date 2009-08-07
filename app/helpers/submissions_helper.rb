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
      result[file.id] = construct_table_row(file_name, file)
    end
    return result
  end
  
  
 def construct_submissions_table_row(grouping, assignment)
    table_row = {}
    table_row[:id] = grouping.id
    table_row[:filter_table_row_contents] = render_to_string :partial => 'submissions/submissions_table_row/filter_table_row', :locals => {:grouping => grouping, :assignment => assignment}
    
    table_row[:group_name] = grouping.group.group_name
    #render_to_string :partial => "submissions/submissions_table_row/group_name", :locals => {:grouping => grouping}
    
    table_row[:repository] = grouping.group.repository_name
    #render_to_string :partial => "submissions/submissions_table_row/repository", :locals => {:grouping => grouping}

    table_row[:commit_date] = ''
    #render_to_string :partial => "submissions/submissions_table_row/commit_date", :locals => {:grouping => grouping}

    table_row[:marking_state] = ''
    #render_to_string :partial => "submissions/submissions_table_row/marking_state", :locals => {:grouping => grouping, :assignment => assignment}

    table_row[:final_grade] = ''
    #render_to_string :partial => "submissions/submissions_table_row/final_grade", :locals => {:grouping => grouping}

    table_row[:released] = ''
    #render_to_string :partial => "submissions/submissions_table_row/released", :locals => {:grouping => grouping}

    return table_row
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
