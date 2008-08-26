class SubmissionsController < ApplicationController
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  def submit
    @assignment = Assignment.find(params[:id])
    # user id is used for group_number on individual submissions
    if @assignment.individual? # an individual assignment, no groups
      @submissions = Submission.submitted_files(current_user.id, params[:id])
      return
    end
    
    # check where to redirect
    @group = Group.find_group(current_user.id, params[:id])
    if not @group
      # user is not in a group
      redirect_to :action => 'creategroup', :id => params[:id]
      
    elsif not @group.in_group?
      # user has been invited to join a group
      redirect_to :action => 'join', :id => params[:id]
      
    else
      # user is in a group
      group_number = @group.group_number
      @members = @group.members
       # count number of joined members
      @num_mbrs = @members.inject(0) do |count, m|
        m.in_group? ? count + 1 : count
      end
      if @num_mbrs < @assignment.group_min
        flash[:status] = "You can only submit once you have at least " + 
          @assignment.group_min.to_s + " member(s) in the group"
        render :action => 'status', :id => params[:id]
      end
      @submissions = Submission.submitted_files(group_number, params[:id])
    end
    
  end
  
  # Handles file upload
  def upload
    @assignment = Assignment.find(params[:id])
    redirect_to :action => 'submit', :id => params[:id] unless request.post?
    indiv = @assignment.individual?
    
    # check if user is indeed allowed to submit
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
    
    # check if submitting past deadline
    submission_time = Time.now
    due_date = @assignment.due_date
    if submission_time > due_date
      # check how many grace days user has used so far 
      # by looking at last submission date
      lst = Submission.last_submission(current_user, group_number, @assignment)
      grace_days = Submission.get_used_grace_days(lst, @assignment)
      if submission_time > due_date.advance(:days => grace_days)
        # we need to use another grace day. check if we have enough
        gd_left = group ? group.grace_days : current_user.grace_days
        
        unless gd_left > 0  # no more grace days
          flash[:error] = "Deadline has passed. You cannot submit anymore."
          redirect_to :action => 'submit', :id => params[:id]
          return
        end
        
        # check if user wants to use a grace day
        if params[:group] && (params[:group]['use_grace_day'] == "1")
          # verify grace days has been properly updated
          unless use_grace_day(current_user, group)
            flash[:error] = "There was a problem updating your grace days. Please re-submit."
            redirect_to :action => 'submit', :id => params[:id]
            return
          end
        else
          flash[:error] = "Deadline has passed. Use your grace days and re-submit."
          flash[:grace_days] = gd_left
          redirect_to :action => 'submit', :id => params[:id]
          return
        end
      end
      # user can still submit using current grace days
    end
    
    # sanitize submitted files first
    # check for duplicate files and required files
    assignment_files = @assignment.assignment_files.index_by { |f| f.filename.to_s }
    valid_files = sanitize_files(assignment_files, params[:files])
    
    # get submission information
    user = @assignment.individual? ? current_user : 
      Group.inviter(group_number, @assignment.id).user
    dir = submission_dir(@assignment.name, user.user_name, 
      Submission.get_version(submission_time))
    
    # upload files
    flash[:success] = []
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
        flash[:success] << filename + (file.size > 0 ? "" : " (blank file)")
      else # save failed
        flash[:submit_files] << "<b>#{filename}</b> cannot be saved at this time"
      end
    end
    
    redirect_to :action => 'submit', :id => params[:id]
  end
  
  def view
    @assignment = Assignment.find(params[:id])
    file = @assignment.assignment_files.find_by_filename(params[:filename])
    render :text => "File not found", :status => 404 && return unless file
    individual = @assignment.individual?
    
    user = current_user
    unless individual
      group = Group.find_group(user.id, @assignment.id)
      user = group.inviter.user
    end
    
    # find last submission date of the assignment file
    conditions = { 
      :assignment_file_id => file.id,
      :user_id => user.id,
      :group_number => individual ? user.id : group.group_number
    }
    submission_time = Submission.find(:first, :order => "submitted_at DESC", 
      :conditions => conditions).submitted_at
    dir = submission_dir(@assignment.name, user.user_name, 
      Submission.get_version(submission_time))
    
    # get file and show it
    path = File.join(dir, file.filename)
    unless File.exists?(path)
      render :text => "File not found", :status => 401
      return
    end
    send_file path, :type => 'text/plain', :disposition => 'inline'
  end
  
  # 
  def join
    @assignment = Assignment.find(params[:id])
    assignment_id = @assignment.id
    @group = Group.find_group(current_user.id, assignment_id)
    
    redirect_to :action => 'creategroup', :id => assignment_id unless @group
    
    if @group && !@group.in_group?  # group member has pending status
      @inviter = @group.inviter.user
      return unless request.post?
      if params[:accept]
        @group.accept_invite
        @group.save  # TODO verify it is indeed saved
      elsif params[:reject]
        @group.reject_invite
      else
        # somebody's not doing the right thing...
      end
      redirect_to :action => 'submit', :id => assignment_id
    end
  end
  
  # Creates a group and invite members specified
  def creategroup
    # TODO verify user is not in a group, (they can't create anyways)
    @assignment = Assignment.find(params[:id])
    @groups = params[:groups]
    
    return unless request.post?
    
    # create a new group
    @group = form_new
    return unless @group.save
    @group.group_number = @group.id
    
    if params[:group] && params[:group]['individual'] == "1"
      # redirect to submit page if person is working alone
      @group.save
      redirect_to(:action => 'submit', :id => params[:id])
      return
    else
      # invite users to this group
      members = add_members(@group, params[:groups].values)
    
      # TODO we might not need this restriction. redirect instead to status page
      # check if we have enough members or has at least one member 
      # if not working individually
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
      @group.destroy  # ugly, but necessary. use transactions next time?
    end
  end
  
  # Shows group status and a way to invite additional members 
  # to the group for the inviter member
  def status
    action_init(params[:id])
    @members = @group.members
    
    # add additional members to the group
    return unless request.post?
    members = add_members(@group, params[:groups].values)
    if @group.errors.empty? && members.all?(&:valid?)
      redirect_to(:action => 'status', :id => @assignment.id) if members.all?(&:save)
    end
  end
  
  private
  
  # Helper method to do most common tasks for action: fetch assignment 
  # and group, and redirect to appropriate page if necessary
  def action_init(aid)
    @assignment = Assignment.find(aid)
    @group = Group.find_group(current_user, @assignment.id)
    unless @group || @assignment.individual?
      redirect_to :action => 'creategroup', :id => aid
    end
  end
  
  # add hash of member usernames { 'user_name' => <user_name> } to this group
  def add_members(group, members)
    # invite users to this group
    valid_members = []
    members.each do |m|
      user_name = m['user_name'].strip
      member = invite(group, user_name) unless user_name.blank?
      valid_members << member if member
    end
    
    # verify that group does not exceed group max
    if group.members.length > @assignment.group_max
      group.errors.add_to_base("You have exceeded number of members allowed for this assignment")
      return []
    end
    return valid_members
  end
  
  
  
  # deducts a grace day for all members in the group or for user
  # returns true if users has been successfully updated
  def use_grace_day(user, group)
    if group
      members = group.joined_members
      begin
        Group.transaction do
          members.each do |m|
            m.user.grace_days -= 1
            m.save!
          end
        end
      rescue
        return false
      end
      
    else
      user.grace_days -= 1
      return user.save
    end
  end
  
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
    end if files
    
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
    elsif member.user_name == current_user.user_name
      group.errors.add_to_base("You cannot invite yourself to your own group")
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
  
  # Creates and returns the path where to store
  # submission_folder/assignment_name/user or group name/submission_date/filename
  def submission_dir(assignment_name, user_folder, version)
    path = File.join(SUBMISSIONS_PATH, assignment_name, user_folder, version)
    FileUtils.mkdir_p(path)
    return path
  end
  
  
end
