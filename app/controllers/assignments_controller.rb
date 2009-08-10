class AssignmentsController < ApplicationController
  before_filter      :authorize_only_for_admin, :except =>
  [:populate, :deletegroup, :delete_rejected, :disinvite_member, :invite_member, :creategroup, :join_group, :decline_invitation, :file_manager, :index, :download, :student_interface, :hand_in, :update_files]

  auto_complete_for :assignment, :name
  # Publicly accessible actions ---------------------------------------
  
  def student_interface
    @assignment = Assignment.find(params[:id])
    @student = Student.find(session[:uid]) 
    @grouping = @student.accepted_grouping_for(@assignment.id)
    if @student.has_pending_groupings_for?(@assignment.id)
      @pending_grouping = @student.pending_groupings_for(@assignment.id) 
    end

    if @grouping.nil?
      if @assignment.group_max == 1
        @student.create_group_for_working_alone_student(@assignment.id)
        redirect_to :action => 'student_interface', :id => @assignment.id
      else
        render :action => 'student_interface', :layout => 'no_menu_header'
        return
      end
    end
   
    if !@grouping.nil?
      # We look for the informations on this group
      # The members
      @studentmemberships =  @grouping.student_memberships
      # The group name
      @group = @grouping.group
      # The inviter   
      @inviter = @grouping.inviter

      # We search for information on the submissions
      path = '/'
      repo = @grouping.group.repo
      @revision  = repo.get_latest_revision
      @directories = @revision.directories_at_path(File.join(@assignment.repository_folder, path))
      @files =   @revision.files_at_path(File.join(File.join(@assignment.repository_folder, path)))
      @missing_assignment_files = []
      @assignment.assignment_files.each do |assignment_file|
        if !@revision.path_exists?(File.join(@assignment.repository_folder, assignment_file.filename))
          @missing_assignment_files.push(assignment_file)
        end
      end
    end
  end


  def download
    file_name = params[:file_name]
    path = params[:path] || '/'
    assignment_id = params[:id]
    revision_number = params[:revision_number]
    assignment = Assignment.find(assignment_id)
    assignment_folder = assignment.repository_folder
    user_group = current_user.accepted_grouping_for(assignment_id).group
    repo = user_group.repo
    revision = repo.get_revision(revision_number.to_i)
    file = revision.files_at_path(File.join(assignment_folder, path))[file_name]
    if file.nil?
      @file_contents = "Could not find the file #{file_name} in the repository for group #{user_group.group_name} for revision #{revision.revision_number}"
    else
      @file_contents = repo.download_as_string(file)
    end
    # Blast the file contents
    send_data @file_contents, :type => 'text/plain', :disposition => 'inline', :filename => file_name
  end
  
  # Displays "Manage Assignments" page for creating and editing 
  # assignment information
  def index
    @assignments = Assignment.all(:order => :id)
    if current_user.student?
      # get results for assignments for the current user
      @a_id_results = Hash.new()
      @assignments.each do |a|
        if current_user.has_accepted_grouping_for?(a)
          grouping = current_user.accepted_grouping_for(a)
          if grouping.has_submission?
            submission = grouping.get_submission_used
            if submission.has_result?
              if submission.result.released_to_students
                @a_id_results[a.id] = submission.result
              end
            end
          end 
        end
      end
      render :action => "student_assignment_list"
      return
    else
      render :action => 'index'
    end
  end
  
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    @assignments = Assignment.all
    if !request.post?
      return
    end
    
    # Was the SubmissionRule changed?  If so, wipe out any existing
    # Periods, and switch the type of the SubmissionRule.
    # This little conditional has to do some hack-y workarounds, since
    # accepts_nested_attributes_for is a little...dumb.
    if @assignment.submission_rule.attributes['type'] != params[:assignment][:submission_rule_attributes][:type]
      @assignment.submission_rule.destroy
      submission_rule = SubmissionRule.new
      # A little hack to get around Rails' protection of the "type"
      # attribute
      submission_rule.type = params[:assignment][:submission_rule_attributes][:type]
      @assignment.submission_rule = submission_rule
      # For some reason, when we create new rule, we can't just apply
      # the params[:assignment] hash to @assignment.attributes...we have
      # to create any new periods manually, like this:
      @assignment.submission_rule.periods_attributes = params[:assignment][:submission_rule_attributes][:periods_attributes]
    end

    # Is the instructor forming groups?
    if params[:is_group_assignment] == "true" && params[:assignment][:student_form_groups] == "0"
      params[:assignment][:instructor_form_groups] = true
    else
      params[:assignment][:instructor_form_groups] = false
    end
    
    @assignment.attributes = params[:assignment]
    
    if @assignment.save
      flash[:notice] = "Successfully Updated Assignment"
      redirect_to :action => 'edit', :id => params[:id]
      return
    else
      render :action => 'edit'
    end
 end

  
  # Ajax support for adding another file text field for this assignment
  def add_assignment_file
    @assignment = Assignment.find(params[:id])
    new_assignment_file_name = params[:new_assignment_filename]
    # Check to see if a file with this filename already exists
    exist_filename = @assignment.assignment_files.find_by_filename(new_assignment_file_name)
    if exist_filename
      render :update do |page|
        page.visual_effect :highlight, "assignment_file_#{exist_filename.id}"
      end
      return
    end
    @assignment_file = AssignmentFile.new
    @assignment_file.assignment = @assignment
    @assignment_file.filename = params[:new_assignment_filename]
    @assignment_file.save
    render :update do |page|
      page.insert_html :bottom, :files, :partial => 'file_fields', :locals => {:assignment_file => @assignment_file}
    end
  end
  
  def remove_assignment_file
    if request.post?
      assignment_file = AssignmentFile.find(params[:id])
      assignment_file.destroy
      render :update do |page|
        page.remove "assignment_file_#{assignment_file.id}"
      end
    end
  end
  

  # Form accessible actions --------------------------------------------
  # Post actions that we expect only forms to access them
  
  # Called when form for creating a new assignment is submitted
  def new
    @assignments = Assignment.all
    @assignment = Assignment.new
    @assignment.build_submission_rule
    #@assignment.assignment_files.build
    if !request.post?
      render :action => 'new'
      return
    end
    # Is the instructor forming groups?
    if params[:is_group_assignment] == "true" && params[:assignment][:student_form_groups] == "0"
      params[:assignment][:instructor_form_groups] = true
    else
      params[:assignment][:instructor_form_groups] = false
    end
    
    @assignment = Assignment.new(params[:assignment])

    # A little hack to get around Rails' protection of the "type"
    # attribute
    @assignment.submission_rule.type = params[:assignment][:submission_rule_attributes][:type]
    

    @assignment.transaction do

      if !@assignment.save
        render :action => :new
        return
      end
      if params[:assignment_files]
        params[:assignment_files].each do |assignment_file_name|
          if !assignment_file_name.empty?
            assignment_file = AssignmentFile.new(:filename => assignment_file_name, :assignment => @assignment)
            assignment_file.save
          end
        end
      end
      if params[:persist_groups_assignment]
        @assignment.clone_groupings_from(params[:persist_groups_assignment])
      end
      @assignment.save
    end
    redirect_to :action => "edit", :id => @assignment.id
  end
  
  def update_group_properties_on_persist
    assignment = Assignment.find(params[:assignment_id])
    render :update do |page|
      page.call "update_group_properties", (assignment.group_max != 1), assignment.student_form_groups, assignment.group_min, assignment.group_max, assignment.group_name_autogenerated
      
    end
  end
  
  # Called when form for updating existing assignment is submitted
  def update
    return unless request.post?
    
    @assignment = Assignment.find_by_id(params[:id])
    @assignment.attributes = params[:assignment]
    
    rules = @assignment.submission_rule
    # must be explicitly assigned, due to method conflict for "type"
    rules[:type] = params[:submission_rule][:type]
    rules.attributes = params[:submission_rule]

    # Go back to "Edit assignment" page if unable to save
    if (@assignment.save && @assignment.assignment_files.each(&:save) && rules.save)
      redirect_to :action => 'edit', :id => @assignment.id
    else
      render :action => 'edit'
    end
    end

  def use_another_assignment_groups
    render :update do |page|
      page.visual_effect(:appear, "other_assignment_groups", :duration => 0.5)
      page.visual_effect(:fade, "group_choice", :duration => 0.5)
    end
  end

  def new_group_properties
    render :update do |page|
         page.visual_effect(:appear, "group_properties", :duration => 0.5)
         page.visual_effect(:fade, "group_choice", :duration => 0.5)
     end    
  end


  def cancel
    render :update do |page|
         page.visual_effect(:fade, "group_properties", :duration => 0.5)
         page.visual_effect(:appear, "group_choice", :duration => 0.5)
         page.visual_effect(:fade, "other_assignment_groups", :duration => 0.5)
     end
    

  end


  # student interface's method

  def join_group
    @assignment = Assignment.find(params[:id]) 
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @user.join(@grouping.id)
  end

  def decline_invitation
     @assignment = Assignment.find(params[:id])
     @grouping = Grouping.find(params[:grouping_id])
     @user = Student.find(session[:uid])
     @grouping.decline_invitation(@user)
     return
  end

  def creategroup
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    @student = Student.find(session[:uid])

    if params[:workalone]
      @student.create_group_for_working_alone_student(@assignment.id)
    else
      @student.create_autogenerated_name_group(@assignment.id)
    end
  end

  def deletegroup
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    if @grouping.has_submission?
      flash[:fail_notice] = "You already submitted something. You cannot
      delete your group."
    else
      @grouping.student_memberships.all(:include => :user).each do |member|
        member.destroy
      end
      @grouping.destroy
      flash[:edit_notice] = "Group has been deleted"
    end
  end

  def invite_member
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    @student = Student.find(session[:uid])
    @grouping = @student.accepted_grouping_for(@assignment.id)
    @invited = Student.find_by_user_name(params[:invite_member])


    if @invited.nil?
      flash[:fail_notice] = "This student doesn't exist."
      return
    end
    if @invited == @student
      flash[:fail_notice] = "You cannot invite yourself to your own group"
      return
    end

    if @invited.hidden
      flash[:fail_notice] = "Could not invite this student - this student's account has been disabled."
      return
    end
    if !@grouping.pending?(@invited)
      @invited.invite(@grouping.id)
      flash[:edit_notice] = "Student invited."
    else
     flash[:fail_notice] = "This student is already a pending member of this group!"
    end
  end

  def disinvite_member
    @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    membership.delete
    membership.save
    flash[:edit_notice] = "Member disinvited" 
  end

  def delete_rejected
  @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    membership.delete
    membership.save
  end  

end
