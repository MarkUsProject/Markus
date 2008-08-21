class SubmissionsController < ApplicationController
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  def submit
    @assignment = Assignment.find(params[:id])
    files = (@assignment.assignment_files.map { |v| v.filename }).join(',')
    # user id is used for group_number on individual submissions
    session[:group_number] = current_user.id
    if @assignment.individual? # an individual assignment, no groups
      @submissions = Submission.submitted_files(session[:group_number])
      return
    end
    
    # check where to redirect
    @group = Group.find_group(current_user.id, params[:id])
    if not @group
      # user is not in a group
      session[:group_number] = nil
      redirect_to :action => 'creategroup', :id => params[:id]
      
    elsif not @group.in_group?
      # user has been invited to join a group
      session[:group_number] = nil
      redirect_to :action => 'join', :id => params[:id]
      
    else
      # user is in a group
      # TODO check number of joined members in the group
      session[:group_number] = @group.group_number
      @members = @group.members
      @has_enough = @group.count_joined_members >= @assignment.group_min
      @submissions = Submission.submitted_files(session[:group_number])
    end
    
  end
  
  # Handles file upload
  def upload
    @assignment = Assignment.find(params[:id])
    redirect_to :action => 'submit', :id => params[:id] unless request.post?
    
    # check if user is indeed allowed to submit and is not passed deadline
    if @assignment.individual?
      group_number = current_user.id
    else
      group = Group.find_group(current_user.id, params[:id])
      unless group && group.in_group?
        flash[:submit] = "You must be in a group to submit"
        redirect_to :action => 'submit', :id => params[:id]
        return
      end
      group_number = group.group_number
    end
    
    # sanitize submitted files first
    # check for duplicate files, empty files and required files
    assignment_files = @assignment.assignment_files.index_by { |f| f.filename.to_s }
    valid_files = sanitize_files(assignment_files, params[:files])
    
    # get submission information
    user = @assignment.individual? ? current_user : 
    Group.inviter(group_number, @assignment.id).user
    submission_time = Time.now
    dir = submission_dir(@assignment.name, user.user_name, 
      submission_time.strftime("%m-%d-%Y"))
    
    # upload files
    valid_files.each_pair do |filename, file|
      filepath = File.join(dir, filename)
      sub = Submission.new do |s|
        s.assignment_file_id = assignment_files[filename].id
        s.user_id = user.id
        s.group_number = group_number
        s.submitted_at = submission_time
      end
      
      # make sure that the submission has been recorded properly before uploading
      if sub.save
        File.open(filepath, "wb") { |f| f.write(file.read) }
      else # save failed
        flash[:submit_files] << "<b>#{filename}</b> cannot be saved at this time"
      end
    end
    
    redirect_to :action => 'submit', :id => params[:id]
  end
  
  def view
    assignment = Assignment.find(params[:id])
    file = assignment.assigment_files.find_by_filename(params[:filename])
    individual = @assignment.individual?
    return unless file
    
    user = current_user
    unless individual
      group = Group.find_group(user.id, assignment.id)
      user = group.inviter(assignment.id).user
    end
    
    # find last submission date
    conditions = { 
      :assignment_file_id => file.id,
      :user_id => user.id,
      :group_number => individual ? user.id : group.group_number
    }
    submission_time = Submission.find(:first, 
      :order => "submitted_at DESC", :conditions => conditions).submitted_at
    dir = submission_dir(@assignment.name, user.user_name, 
      submission_time.strftime("%m-%d-%Y"))
    
    # get file and show it
    path = File.join(submission_dir, file.filename)
    send_file path, :type => 'text/plain', :disposition => 'inline'
  end
  
  def join
    @assignment = Assignment.find(params[:id])
    assignment_id = @assignment.id
    @group = Group.find_group(current_user.id, assignment_id)
    
    redirect_to :action => 'creategroup', :id => assignment_id unless @group
    
    unless @group.in_group?
      @inviter = @group.inviter(assignment_id).user
      return unless request.post?
      params[:accept] ? @group.accept_invite : @group.reject_invite
      @group.save unless @group.frozen?
      redirect_to :action => 'submit', :id => assignment_id
    end
  end
  
  # Creates a group and invite members specified
  def creategroup
    @assignment = Assignment.find(params[:id])
    @groups = params[:groups]
    
    return unless request.post?
    
    # create a new group
    @group = form_new
    return unless @group.save
    @group.group_number = @group.id
    
    if params[:group] && params[:group]['individual'] == "1"
      # redirect to submit page if person is working alone
      redirect_to(:action => 'submit', :id => params[:id])
    else
      # invite users to this group
      members = []
      params[:groups].each_value do |m|
        user_name = m['user_name'].strip
        member = invite(@group, user_name) unless user_name.blank?
        members << member if member
      end
      
      # check if we have enough members or has at least one member if not 
      # working individually
      group_min = @assignment.group_min - 1
      if members.length < group_min || group_min == 0
        @group.errors.add_to_base(
          "You need to have at least #{[group_min, 1].max} valid user name(s)")
      end
    end
    
    # check if we do not have any errors
    if @group.errors.empty? && members.all?(&:valid?)
      @group.save
      redirect_to(:action => 'status', :id => @assignment.id) if members.all?(&:save)
    else
      @group.destroy
    end
    
  end
  
  
  private
  
  # filters user-submitted files to make sure that only required files are 
  # submitted with no duplicates.
  # assignment_files - a hash of AssignmentFile objects with filenames as key
  # files - array of hashes of UploadStringIO from upload parameters
  # Returns a hash of UploadedStringIO with filenames as keys.  excluded files 
  # are added to flash[:submit] array
  def sanitize_files(assignment_files, files)
    flash[:submit_files] = []  # invalid messages here
    valid_files = {}
    
    files.each_value do |file|
      unless file[:file].blank? # ignore blank lines
        filename = CGI.escapeHTML(file[:file].original_filename).strip # sanitized
        
        # check if filename is not a required assignment file
        if not assignment_files[filename]
          flash[:submit_files] << "<b>#{filename}</b> is not a valid assignment file"
          
          # check if filename is a duplicate.
        elsif valid_files[filename]
          flash[:submit_files] << "<b>#{filename}</b> is being submitted more than once"
          valid_files.delete(filename)
          
          # filename is a valid file
        else
          valid_files[filename] = file[:file]
        end
      end
    end
    
    return valid_files
  end
  
  # Create a new group
  def form_new
    g = Group.new
    g.assignment = @assignment
    g.status = 'inviter'
    g.user = current_user
    
    return g
  end
  
  def invite(group, user_name)
    # check if a valid user
    member = User.find_by_user_name(user_name)
    if not member
      group.errors.add_to_base("username '" + 
          CGI.escapeHTML(user_name) + "' is not valid")
      return nil
    end
    
    # check if user is already in a group
    in_member = Group.find_group(member.id, @assignment.id)
    if in_member
      str = in_member.in_group? ? "already in" : "being invited to"
      group.errors.add_to_base(user_name + " is #{str} a group")
      return nil
    end
    
    # create a new member
    g = Group.new do |m|
      m.group_number = group.group_number
      m.assignment_id = group.assignment_id
      m.status = 'pending'
    end
    g.user = member
    return g
  end
  
  def status
    #Group.find_group(user_id, assignment_id)
  end
  
  
  # Creates and returns the path where to store
  # submission_folder/assignment_name/user or group name/submission_date/filename
  def submission_dir(assignment_name, user_folder, version)
    path = File.join(SUBMISSIONS_PATH, assignment_name, user_folder, version)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    return path
  end
  
  
end
