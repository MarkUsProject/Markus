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

  def construct_table_row(file_name, file)
    table_row = {}

    table_row[:id] = file.id

    table_row[:filename] = render_to_string :partial =>
    "submissions/table_row/filename", :locals => {:file => file,:file_name => file_name}
    
    table_row[:last_modified_date] = render_to_string :partial => "submissions/table_row/last_modified_date", :locals => {:file => file}

    table_row[:last_modified_date_unconverted] = render_to_string :partial => "submissions/table_row/last_modified_date_for_js", :locals => {:file => file}

    table_row[:revision_by] = render_to_string :partial => "submissions/table_row/revision_by", :locals => {:file => file,:file_name => file_name}

    table_row[:replace] = render_to_string :partial => "submissions/table_row/replace", :locals => {:file => file,:file_name => file_name}

    table_row[:delete_file] = render_to_string :partial => "submissions/table_row/delete_file", :locals => {:file => file,:file_name => file_name}

    return table_row
  end

  def construct_table_rows(files)
    result = {}
    files.each do |file_name, file|
      result[file.id] = construct_table_row(file_name, file)
    end
    return result
  end
  
  def sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return "" if file_name.nil?
    return File.basename(file_name).gsub(/[^\w\.\-]/, '_')
  end
  
end
