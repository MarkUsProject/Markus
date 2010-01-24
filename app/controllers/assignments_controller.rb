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
        render :action => 'student_interface', :layout => 'no_menu_header'
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

      # Look up submission information
      repo = @grouping.group.repo
      @revision  = repo.get_latest_revision
      @last_modified_date = @grouping.assignment_folder_last_modified_date
      @num_submitted_files = @grouping.number_of_submitted_files
      @num_missing_assignment_files = @grouping.missing_assignment_files.length
    end
  end
  
  # Displays "Manage Assignments" page for creating and editing 
  # assignment information
  def index
    @assignments = Assignment.all(:order => :id)
    @grade_entry_forms = GradeEntryForm.all(:order => :id)
    if current_user.student?
      # get results for assignments for the current user
      @a_id_results = Hash.new()
      @assignments.each do |a|
        if current_user.has_accepted_grouping_for?(a)
          grouping = current_user.accepted_grouping_for(a)
          if grouping.has_submission?
            submission = grouping.get_submission_used
            if submission.has_result? && submission.result.released_to_students
                @a_id_results[a.id] = submission.result
            end
          end 
        end
      end
      render :action => "student_assignment_list"
      return
    elsif current_user.ta?
      render :action => "grader_index"
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
  
    begin
      @assignment = process_assignment_form(@assignment, params)
    rescue Exception, RuntimeError => e
      @assignment.errors.add_to_base("Could not assign SubmissionRule: #{e.message}")
      return
    end
    
    if @assignment.save
      flash[:success] = "Successfully updated assignment"
      redirect_to :action => 'edit', :id => params[:id]
      return
    else
      render :action => 'edit'
    end
 end
  

  # Form accessible actions --------------------------------------------
  # Post actions that we expect only forms to access them
  
  # Called when form for creating a new assignment is submitted
  def new
    @assignments = Assignment.all
    @assignment = Assignment.new
    @assignment.build_submission_rule
    
    if !request.post?
      # set default value if web submits are allowed
      @assignment.allow_web_submits = markus_config_repository_external_submits_only?
      render :action => 'new'
      return
    end   

    @assignment.transaction do
      begin
        @assignment = process_assignment_form(@assignment, params)
      rescue Exception, RuntimeError => e
        @assignment.errors.add_to_base(e.message)
      end
      if !@assignment.save
        render :action => :new
        return
      end
      if params[:persist_groups_assignment]
        @assignment.clone_groupings_from(params[:persist_groups_assignment])
      end
      if @assignment.save
        flash[:success] = "Successfully created assignment"
      end
    end

    redirect_to :action => "edit", :id => @assignment.id
  end
  
  def update_group_properties_on_persist
    @assignment = Assignment.find(params[:assignment_id])
  end
  
  def download_csv_grades_report
    assignments = Assignment.all(:order => 'id')
    students = Student.all
    csv_string = FasterCSV.generate do |csv|
      students.each do |student|
        row = []
        row.push(student.user_name)
        assignments.each do |assignment|
          out_of = assignment.total_mark
          grouping = student.accepted_grouping_for(assignment.id)
          if grouping.nil?
            row.push('')
          else
            submission = grouping.get_submission_used
            if submission.nil?
              row.push('')
            else
              total_mark_percentage = submission.result.total_mark / out_of * 100
              if total_mark_percentage.nan?
                row.push('')
              else
                row.push(total_mark_percentage)
              end
            end
          end
        end
        csv << row
      end
    end
    send_data csv_string, :disposition => "attachment", :filename => "#{COURSE_NAME} grades report.csv"
  end


  # Methods for the student interface

  def join_group
    @assignment = Assignment.find(params[:id]) 
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @user.join(@grouping.id)
    m_logger = MarkusLogger.instance
    m_logger.log(I18n.t("markus_logger.student_accepted_invitation", :user_name => @user.user_name, :group => @grouping.group.group_name))
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def decline_invitation
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @grouping.decline_invitation(@user)
    m_logger = MarkusLogger.instance
    m_logger.log(I18n.t("markus_logger.student_declined_invitation", :user_name => @user.user_name, :group => @grouping.group.group_name))
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def creategroup
    @assignment = Assignment.find(params[:id])
    @student = @current_user
    m_logger = MarkusLogger.instance
    
    begin
      # We do not allow group creations by students after the due date
      # and the grace period for an assignment
      if @assignment.past_collection_date?
        raise I18n.t('create_group.fail.due_date_passed')
      end
      if !@assignment.student_form_groups || @assignment.instructor_form_groups
        raise "Assignment does not allow students to form groups"
      end
      if @student.has_accepted_grouping_for?(@assignment.id)
        raise "You already have a group, and cannot create another"
      end
      if params[:workalone] && @assignment.group_min != 1
          raise "You cannot work alone for this assignment - the group size minimum is #{@assignment.group_min}"
      end
      @student.create_autogenerated_name_group(@assignment.id)
      m_logger.log(I18n.t("markus_logger.student_created_group", :user_name => @student.user_name), MarkusLogger::INFO)
    rescue RuntimeError => e
      flash[:fail_notice] = e.message
      m_logger.log(I18n.t("markus_logger.student_create_group_fail", :user_name => @student.user_name, :error => e.message), MarkusLogger::ERROR)
    end
    redirect_to :action => 'student_interface', :id => @assignment.id
  end

  def deletegroup
    @assignment = Assignment.find(params[:id])
    @grouping = @current_user.accepted_grouping_for(@assignment.id)
    m_logger = MarkusLogger.instance
    begin
      if @grouping.nil?
        raise "You do not currently have a group"
      end
      # If grouping is not deletable for @current_user for whatever reason, fail.
      if !@grouping.deletable_by?(@current_user)
        raise I18n.t('groups.cant_delete')
      end
      if @grouping.has_submission?
        raise I18n.t('groups.cant_delete_already_submitted')
      end
      @grouping.student_memberships.all(:include => :user).each do |member|
        member.destroy
      end
      # update repository permissions
      @grouping.update_repository_permissions
      @grouping.destroy
      flash[:edit_notice] = "Group has been deleted"
      m_logger.log(I18n.t("markus_logger.student_deleted_group", :user_name => current_user.user_name, :group => @grouping.group.group_name), MarkusLogger::INFO)
    
    rescue RuntimeError => e
      flash[:fail_notice] = e.message
      if @grouping.nil?
        m_logger.log(I18n.t("markus_logger.student_delete_group_fail_no_grouping", :user_name => current_user.user_name, :error => e.message), MarkusLogger::ERROR)
      else
        m_logger.log(I18n.t("markus_logger.student_delete_group_fail", :user_name => current_user.user_name, :group => @grouping.group.group_name, :error => e.message), MarkusLogger::ERROR)
      end
    end
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def invite_member
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    # if instructor formed group return
    return if @assignment.instructor_form_groups
    
    @student = @current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)
    if @grouping.nil?
      raise I18n.t('invite_student.fail.need_to_create_group')
    end
    
    to_invite = params[:invite_member].split(',')
    flash[:fail_notice] = []
    flash[:success] = []
    m_logger = MarkusLogger.instance
    to_invite.each do |user_name|
      user_name = user_name.strip
      @invited = Student.find_by_user_name(user_name)
      begin
        # we want to allow group invitations after the due date,
        # but before the grace period time (if any)
        if @assignment.past_collection_date?
          raise I18n.t('invite_student.fail.due_date_passed', :user_name => user_name)
        end
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
        m_logger.log(I18n.t("markus_logger.student_invited_student", :inviter => @student.user_name, :invitee => @invited.user_name))
      rescue Exception => e
        flash[:fail_notice].push(e.message)
	invitee = nil
	if !@invited.nil?
	  invitee = @invited.user_name
	else
	  invitee = user_name
	end
        m_logger.log(I18n.t('markus_logger.student_invitation_failure',
                            { :inviter => @student.user_name, :invitee => invitee,
                              :error => e.message }), MarkusLogger::ERROR)
      end
    end
    redirect_to :action => 'student_interface', :id => @assignment.id
  end

  # Called by clicking the cancel link in the student's interface
  # i.e. cancels invitations
  def disinvite_member
    @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    disinvited_student = membership.user
    membership.delete
    membership.save
    # update repository permissions
    grouping = current_user.accepted_grouping_for(@assignment.id)
    grouping.update_repository_permissions
    m_logger = MarkusLogger.instance
    m_logger.log(I18n.t('markus_logger.student_cancelled_invitation', :inviter => current_user.user_name, :invitee => disinvited_student.user_name))
    flash[:edit_notice] = "Member disinvited" 
  end

  # Deletes memberships which have been declined by students
  def delete_rejected
    @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    grouping = membership.grouping
    if current_user != grouping.inviter
      raise "Only the inviter can delete a declined invitation"
    end
    membership.delete
    membership.save
    redirect_to :action => 'student_interface', :id => params[:id]
  end  
  
  private 
  
  def process_assignment_form(assignment, params)
    assignment.attributes = params[:assignment]
    # Was the SubmissionRule changed?  If so, wipe out any existing
    # Periods, and switch the type of the SubmissionRule.
    # This little conditional has to do some hack-y workarounds, since
    # accepts_nested_attributes_for is a little...dumb.
    if assignment.submission_rule.attributes['type'] != params[:assignment][:submission_rule_attributes][:type]
      # Some protective measures here to make sure we haven't been duped...
      potential_rule = Module.const_get(params[:assignment][:submission_rule_attributes][:type])
      if !potential_rule.ancestors.include?(SubmissionRule)
        raise "#{params[:assignment][:submission_rule_attributes][:type]} is not a valid SubmissionRule"
      end
      
      assignment.submission_rule.destroy
      submission_rule = SubmissionRule.new
      # A little hack to get around Rails' protection of the "type"
      # attribute
      submission_rule.type = params[:assignment][:submission_rule_attributes][:type]
      assignment.submission_rule = submission_rule
      # For some reason, when we create new rule, we can't just apply
      # the params[:assignment] hash to @assignment.attributes...we have
      # to create any new periods manually, like this:
      if !params[:assignment][:submission_rule_attributes][:periods_attributes].nil?
        assignment.submission_rule.periods_attributes = params[:assignment][:submission_rule_attributes][:periods_attributes]
      end
    end

    if params[:is_group_assignment] == "true"
      # Is the instructor forming groups?
      if params[:assignment][:student_form_groups] == "0"
        assignment.instructor_form_groups = true
      else
        assignment.student_form_groups = true
        assignment.instructor_form_groups = false
        assignment.group_name_autogenerated = true
      end
    else
      assignment.student_form_groups = false;
      assignment.instructor_form_groups = false;
      assignment.group_min = 1;
      assignment.group_max = 1;
    end
    return assignment
  end

end
