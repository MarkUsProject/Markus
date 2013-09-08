require 'fastercsv'
class AssignmentsController < ApplicationController
  before_filter      :authorize_only_for_admin, :except => [:deletegroup, :delete_rejected, :disinvite_member, :invite_member, 
  :creategroup, :join_group, :decline_invitation, :index, :student_interface]
  before_filter      :authorize_for_student, :only => [:student_interface, :deletegroup, :delete_rejected, :disinvite_member, 
  :invite_member, :creategroup, :join_group, :decline_invitation]
  before_filter      :authorize_for_user, :only => [:index]

  auto_complete_for :assignment, :name
  # Publicly accessible actions ---------------------------------------
  
  def student_interface
    @assignment = Assignment.find(params[:id])
    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)
    if @student.has_pending_groupings_for?(@assignment.id)
      @pending_grouping = @student.pending_groupings_for(@assignment.id) 
    end
    if @grouping.nil?
      if @assignment.group_max == 1
        @student.create_group_for_working_alone_student(@assignment.id)
        redirect_to :action => 'student_interface', :id => @assignment.id
      else
        render :student_interface, :layout => 'no_menu_header'
        return
      end
    else
      # We look for the information on this group...
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
      @last_modified_date = @revision.directories_at_path('/')[@assignment.repository_folder].last_modified_date
      
      @files = @revision.files_at_path(File.join(File.join(@assignment.repository_folder, path)))
      @missing_assignment_files = []
      @assignment.assignment_files.each do |assignment_file|
        unless @revision.path_exists?(File.join(@assignment.repository_folder, assignment_file.filename))
          @missing_assignment_files.push(assignment_file)
        end
      end
    end
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
            if submission.has_result? && submission.get_latest_result.released_to_students
                @a_id_results[a.id] = submission.get_latest_result
            end
          end 
        end
      end
      render :student_assignment_list
    elsif current_user.ta?
      render :grader_index
    else
      render :index
    end
  end
  
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    @assignments = Assignment.all
    unless request.post?
      return
    end
    
    # Was the SubmissionRule changed?  If so, wipe out any existing
    # Periods, and switch the type of the SubmissionRule.
    # This little conditional has to do some hack-y workarounds, since
    # accepts_nested_attributes_for is a little...dumb.
    if @assignment.submission_rule.attributes['type'] != params[:assignment][:submission_rule_attributes][:type]
      # Some protective measures here to make sure we haven't been duped...
      begin
        potential_rule = Module.const_get(params[:assignment][:submission_rule_attributes][:type])
        unless potential_rule.ancestors.include?(SubmissionRule)
          raise "#{params[:assignment][:submission_rule_attributes][:type]} is not a valid SubmissionRule"
        end
      rescue Exception => e
        @assignment.errors.add(:base, "Could not assign SubmissionRule: #{e.message}")
        return
      end
      
      @assignment.submission_rule.destroy
      submission_rule = SubmissionRule.new
      # A little hack to get around Rails' protection of the "type"
      # attribute
      submission_rule.type = params[:assignment][:submission_rule_attributes][:type]
      @assignment.submission_rule = submission_rule
      # For some reason, when we create new rule, we can't just apply
      # the params[:assignment] hash to @assignment.attributes...we have
      # to create any new periods manually, like this:
      if params[:assignment][:submission_rule_attributes][:periods_attributes]
        @assignment.submission_rule.periods_attributes = params[:assignment][:submission_rule_attributes][:periods_attributes]
      end
    end

    # Is the instructor forming groups?
    if params[:is_group_assignment] == 'true' && params[:assignment][:student_form_groups] == '0'
      params[:assignment][:invalid_override] = true
    else
      params[:assignment][:invalid_override] = false
    end
    
    @assignment.attributes = params[:assignment]
    
    if @assignment.save
      flash[:notice] = 'Successfully Updated Assignment'
      redirect_to :action => 'edit', :id => params[:id]
    else
      render :edit
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
    unless request.post?
      render :new
      return
    end
    # Is the instructor forming groups?
    if params[:is_group_assignment] == 'true' && params[:assignment][:student_form_groups] == '0'
      params[:assignment][:invalid_override] = true
    else
      params[:assignment][:invalid_override] = false
    end
    
    @assignment = Assignment.new(params[:assignment])

    # A little hack to get around Rails' protection of the "type"
    # attribute
    @assignment.submission_rule.type = params[:assignment][:submission_rule_attributes][:type]
    

    @assignment.transaction do

      unless @assignment.save
        render :new
        return
      end
      if params[:assignment_files]
        params[:assignment_files].each do |assignment_file_name|
          unless assignment_file_name.empty?
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
    redirect_to :action => 'edit', :id => @assignment.id
  end
  
  def update_group_properties_on_persist
    @assignment = Assignment.find(params[:assignment_id])
  end
  
  def download_csv_grades_report
    assignments = Assignment.all
    students = Student.all
    csv_string = FasterCSV.generate do |csv|
      students.each do |student|
        row = []
        row.push(student.user_name)
        assignments.each do |assignment|
          grouping = student.accepted_grouping_for(assignment.id)
          if grouping.nil?
            row.push('')
          else
            submission = grouping.get_submission_used
            if submission.nil?
              row.push('')
            else
              row.push(submission.get_latest_result.total_mark)
            end
          end
        end
        csv << row
      end
    end
    send_data csv_string, :disposition => 'attachment', :filename => "#{COURSE_NAME} grades report.csv"
  end


  # student interface's method

  def join_group
    @assignment = Assignment.find(params[:id]) 
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @user.join(@grouping.id)
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def decline_invitation
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @grouping.decline_invitation(@user)
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def creategroup
    @assignment = Assignment.find(params[:id])
    @student = @current_user
    
    begin
      if !@assignment.student_form_groups || @assignment.invalid_override
        raise 'Assignment does not allow students to form groups'
      end
      if @student.has_accepted_grouping_for?(@assignment.id)
        raise 'You already have a group, and cannot create another'
      end
      if params[:workalone]
        if @assignment.group_min != 1
          raise "You cannot work alone for this assignment - the group size minimum is #{@assignment.group_min}"
        end
        @student.create_group_for_working_alone_student(@assignment.id)
      else
        @student.create_autogenerated_name_group(@assignment.id)
      end
    rescue RuntimeError => e
      flash[:fail_notice] = e.message
    end
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def deletegroup
    @assignment = Assignment.find(params[:id])
    @grouping = @current_user.accepted_grouping_for(@assignment.id)
    begin
      if @grouping.nil?
        raise 'You do not currently have a group'
      end
      unless @grouping.is_inviter?(@current_user)
        raise 'Only the inviter can delete the group'
      end
      if @grouping.has_submission?
        raise 'You already submitted something. You cannot delete your group.'
      end
      if @grouping.is_valid?
        raise 'Your group is valid, and can only be deleted by instructors.'
      end
      @grouping.student_memberships.all(:include => :user).each do |member|
        member.destroy
      end
      # update repository permissions
      @grouping.update_repository_permissions
      @grouping.destroy
      flash[:edit_notice] = 'Group has been deleted'
    
    rescue RuntimeError => e
      flash[:fail_notice] = e.message
    end
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def invite_member
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    # if instructor formed group return
    return if @assignment.invalid_override
    
    @student = @current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)
    if @grouping.nil?
      raise I18n.t('invite_student.fail.need_to_create_group')
    end
    
    to_invite = params[:invite_member].split(',')
    flash[:fail_notice] = []
    flash[:success] = []
    to_invite.each do |user_name|
      user_name = user_name.strip
      @invited = Student.find_by_user_name(user_name)
      begin
        if @grouping.student_membership_number >= @assignment.group_max
          raise I18n.t('invite_student.fail.group_max_reached', :user_name => user_name)
        end
        if @invited.nil?
          raise I18n.t('invite_student.fail.dne', :user_name => user_name)
        end
        if @invited == @student
          raise I18n.t('invite_student.fail.inviting_self')
        end
        if @invited.hidden
          raise I18n.t('invite_student.fail.hidden', :user_name => user_name)
        end
        if @grouping.pending?(@invited)
          raise I18n.t('invite_student.fail.already_pending', :user_name => user_name)
        end
        if @invited.has_accepted_grouping_for?(@assignment.id)
          raise I18n.t('invite_student.fail.already_grouped', :user_name => user_name)
        end
        
        @invited.invite(@grouping.id)
        flash[:success].push(I18n.t('invite_student.success', :user_name => @invited.user_name))
      rescue Exception => e
        flash[:fail_notice].push(e.message)
      end
    end
    redirect_to :action => 'student_interface', :id => @assignment.id
  end

  # Called by clicking the cancel link in the student's interface
  # i.e. cancels invitations
  def disinvite_member
    @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    membership.delete
    membership.save
    # update repository permissions
    grouping = current_user.accepted_grouping_for(@assignment.id)
    grouping.update_repository_permissions
    flash[:edit_notice] = 'Member disinvited'
  end

  # Deletes memberships which have been declined by students
  def delete_rejected
    @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    membership.delete
    membership.save
    redirect_to :action => 'student_interface', :id => params[:id]
  end  

end
