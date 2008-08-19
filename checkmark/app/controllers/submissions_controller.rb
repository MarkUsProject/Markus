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
      if not @group
        session[:group_number] = nil
        redirect_to :action => 'creategroup', :id => params[:id]
        return
      else
        session[:group_number] = @group.group_number
        if not @group.in_group?
          # TODO redirect to join group
          redirect_to :action => 'join', :id => params[:id]
        end
      end
      
      
      unless @group && @group.in_group?
      end
      session[:group_number] = @group.group_number
    end
    @submissions = Submission.submitted_files(session[:group_number])
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
  
  # Creates and returns the path where to store
  # submission_folder/assignment_name/user or group name/submission_date/filename
  def submission_dir(assignment_name, user_folder, version)
    path = File.join(SUBMISSIONS_PATH, assignment_name, user_folder, version)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    return path
  end
  
  
end
