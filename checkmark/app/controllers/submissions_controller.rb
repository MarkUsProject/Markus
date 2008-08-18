class SubmissionsController < ApplicationController
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  def submit
    @assignment = Assignment.find(params[:id])
    # user id is used for group_number on individual submissions
    session[:group_number] = current_user.id
    
    # redirect to 'create group' page if it is a group assignment 
    # and the user does not belong to a group yet; otherwise get group number
    unless @assignment.individual?
      @group = Group.find_group(current_user.id, params[:id])
      unless @group && @group.in_group?
        session[:group_number] = nil
        render :action => 'creategroup'
        return
      end
      session[:group_number] = @group.group_number
    end
    @submissions = Submission.submitted_files(session[:group_number])
  end
  
  # Handles creation 
  def creategroup
    return unless request.post?
    
    render :controller => 'checkmark'
  end
  
  def status
    
  end
  
  
  # Handles file upload
  def upload
    return unless request.post?
    
    # group number must be set from the submit page
    if session[:group_number]
      assignment = Assignment.find(params[:id])
      # find group inviter's user instance
      inviter = Group.inviter(session[:group_number], assignment.id).user
      submission_time = Time.now
      
      # create a record for the submissions
      Submission.create()
      
      # upload files
      sub_dir = submission_dir(assignment.name, 
        inviter.user_name, submission_time.strftime("%m-%d-%Y"))
      # need to get rid of the whole directory path when uploaded from IE
      filename = params[:file].original_filename
      filename.gsub(/^.*(\\|\/)/, '')
      
      # TODO g6flores: check against list of required files
      @filepath = File.join(sub_dir, filename)
      File.open(@filepath, "wb") { |f| f.write(params[:file].read) }
      
    end
    
    redirect_to :action => 'submit'
  end
  
  
  private
  
  # Sets the group number for this session for the current user given an assignment.
  def set_group_number(assignment)
    if assignment.individual?
      session[:group_number] = current_user.id
    else
      member = Group.find_group(current_user.id, assignment.id)
      session[:group_number] = member ? member.group_number : nil
    end
  end
  
  # Creates and returns the path where to store
  # submission_folder/assignment_name/user or group name/submission_date/filename
  def submission_dir(assignment_name, user_folder, version)
    path = File.join(SUBMISSIONS_PATH, assignment_name, user_folder, version)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    return path
  end
  
  
end
