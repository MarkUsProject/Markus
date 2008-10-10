class SubmissionsController < ApplicationController
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  # Handles file submissions for a form POST, 
  # or displays submission page for the user
  def submit
    @assignment = Assignment.find(params[:id])
    #validate_submit(@assignment)
    submission = @assignment.submission_by(current_user)
    
    if request.post?  # process upload
      flash[:upload] =  { :success => [], :fail => [] }
      sub_time = Time.now  # submission timestamp for all files
      
      params[:files].each_value do |file|
        f = file[:file]
        unless f.blank?
          subfile = submission.submit(current_user, f, sub_time)
          if subfile.valid?
            flash[:upload][:success] << subfile.filename
          else
            flash[:upload][:fail] << subfile.filename
          end
        end
      end if params[:files]
    end
    # display submitted filenames
    @files = submission.submitted_filenames || []
  end
  
  # Handles file viewing submitted by the user or group
  def view
    @assignment = Assignment.find(params[:id])
    submission = @assignment.submission_by(current_user)
    
    # check if user has a submitted file by that filename
    subfile = submission.submission_files.find_by_filename(params[:filename])
    dir = submission.submit_dir
    filepath = File.join(dir, params[:filename])
    
    if subfile && File.exist?(filepath)
      send_file filepath, :type => 'text/plain', :disposition => 'inline'
    else
      render :text => "File not found", :status => 401
    end
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
  
  
end
