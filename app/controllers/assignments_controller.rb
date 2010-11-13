require 'fastercsv'
class AssignmentsController < ApplicationController
  before_filter      :authorize_only_for_admin, 
                     :except => [:deletegroup, 
                                 :delete_rejected, 
                                 :disinvite_member, 
                                 :invite_member, 
                                 :creategroup, 
                                 :join_group, 
                                 :decline_invitation, 
                                 :index, 
                                 :student_interface,
                                 :update_collected_submissions]
  
  before_filter      :authorize_for_student, 
                     :only => [:student_interface, 
                              :deletegroup, 
                              :delete_rejected, 
                              :disinvite_member, 
                              :invite_member, 
                              :creategroup, 
                              :join_group, 
                              :decline_invitation]
  
  before_filter      :authorize_for_user, 
                     :only => [:index]

  auto_complete_for  :assignment, 
                     :name
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
      @revision_number = @revision.revision_number

      # For running tests
      if params[:collect]
        @result = manually_collect_and_prepare_test(@grouping, @revision.revision_number)
      else
        @result = automatically_collect_and_prepare_test(@grouping, @revision.revision_number)
      end
      #submission = @grouping.submissions.find_by_submission_version_used(true)
      if @result
        @test_result_files = @result.submission.test_results
      else
        @test_result_files = nil
      end
      @token = Token.find_by_grouping_id(@grouping.id)
      if @token
        @token.reassign_tokens_if_new_day()
      end
      @last_modified_date = @grouping.assignment_folder_last_modified_date
      @num_submitted_files = @grouping.number_of_submitted_files
      @num_missing_assignment_files = @grouping.missing_assignment_files.length
      repo.close
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
            submission = grouping.current_submission_used
            if submission.has_result? && submission.result.released_to_students
                @a_id_results[a.id] = submission.result
            end
          end 
        end
      end
      
      # Get the grades for grade entry forms for the current user
      @g_id_entries = Hash.new()
      @grade_entry_forms.each do |g|
        grade_entry_student = g.grade_entry_students.find_by_user_id( 
                                    current_user.id )
        if !grade_entry_student.nil? && 
             grade_entry_student.released_to_student
          @g_id_entries[g.id] = grade_entry_student
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
    if !params[:assignment].nil?
      @oldcriteria = @assignment.marking_scheme_type
      @newcriteria = params[:assignment][:marking_scheme_type]
      if @oldcriteria != @newcriteria and !@assignment.get_criteria.nil?
        #TODO use @assignment.criteria.destroy_all when the refactor of 
        # criteria structure finished
        @assignment.get_criteria.each do |criterion|
          criterion.destroy
        end
      end
    end
    @assignments = Assignment.all
    if !request.post?
      return
    end
  
    begin
      @assignment = process_assignment_form(@assignment, params)
    rescue Exception, RuntimeError => e
      @assignment.errors.add_to_base(I18n.t("assignment.error", 
                                            :message => e.message))
      return
    end
    
    if @assignment.save
      flash[:success] = I18n.t("assignment.update_success")
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
      @assignment.allow_web_submits = 
         !MarkusConfigurator.markus_config_repository_external_submits_only?
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
        flash[:success] = I18n.t("assignment.create_success")
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
            submission = grouping.current_submission_used
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
    send_data csv_string, :disposition => "attachment", 
                          :filename => "#{COURSE_NAME} grades report.csv"
  end


  # Methods for the student interface

  def join_group
    @assignment = Assignment.find(params[:id]) 
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @user.join(@grouping.id)
    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{@user.user_name}' joined group '#{@grouping.group.group_name}'" +
                 "(accepted invitation).")
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def decline_invitation
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @grouping.decline_invitation(@user)
    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{@user.user_name}' declined invitation for group '" +
                 "#{@grouping.group.group_name}'.")
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
      if !@assignment.student_form_groups || 
           @assignment.instructor_form_groups
        raise I18n.t('create_group.fail.not_allow_to_form_groups')
      end
      if @student.has_accepted_grouping_for?(@assignment.id)
        raise I18n.t('create_group.fail.already_have_a_group')
      end
      if params[:workalone]
        if @assignment.group_min != 1
          raise I18n.t('create_group.fail.can_not_work_alone', 
                        :group_min => @assignment.group_min)
        end
        @student.create_group_for_working_alone_student(@assignment.id)
      else
        @student.create_autogenerated_name_group(@assignment.id)
      end
      m_logger.log("Student '#{@student.user_name}' created group.",
                   MarkusLogger::INFO)
    rescue RuntimeError => e
      flash[:fail_notice] = e.message
      m_logger.log("Failed to create group. User: '#{@student.user_name}', Error: '" +
                   "#{e.message}'.", MarkusLogger::ERROR)
    end
    redirect_to :action => 'student_interface', :id => @assignment.id
  end

  def deletegroup
    @assignment = Assignment.find(params[:id])
    @grouping = @current_user.accepted_grouping_for(@assignment.id)
    m_logger = MarkusLogger.instance
    begin
      if @grouping.nil?
        raise I18n.t('create_group.fail.do_not_have_a_group')
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
      flash[:edit_notice] = I18n.t('assignment.group.deleted')
      m_logger.log("Student '#{current_user.user_name}' deleted group '" +
                   "#{@grouping.group.group_name}'.", MarkusLogger::INFO)
    
    rescue RuntimeError => e
      flash[:fail_notice] = e.message
      if @grouping.nil?
        m_logger.log(
           "Failed to delete group, since no accepted group for this user existed." +
           "User: '#{current_user.user_name}', Error: '#{e.message}'.", MarkusLogger::ERROR)
      else
        m_logger.log("Failed to delete group '#{@grouping.group.group_name}'. User: '" +
                     "#{current_user.user_name}', Error: '#{e.message}'.", MarkusLogger::ERROR)
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
    @grouping.invite(to_invite)
    flash[:fail_notice] = @grouping.errors["base"]
    if flash[:fail_notice].blank?
      flash[:success] = I18n.t('invite_student.success')
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
    m_logger.log("Student '#{current_user.user_name}' cancelled invitation for " +
                 "'#{disinvited_student.user_name}'.")
    flash[:edit_notice] = I18n.t('student.member_disinvited')
  end

  # Deletes memberships which have been declined by students
  def delete_rejected
    @assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    grouping = membership.grouping
    if current_user != grouping.inviter
      raise I18n.t('invite_student.fail.only_inviter')
    end
    membership.delete
    membership.save
    redirect_to :action => 'student_interface', :id => params[:id]
  end

  def update_collected_submissions
    @assignments = Assignment.all
  end
  
  private 
  
  def process_assignment_form(assignment, params)
    assignment.attributes = params[:assignment]
    # Was the SubmissionRule changed?  If so, wipe out any existing
    # Periods, and switch the type of the SubmissionRule.
    # This little conditional has to do some hack-y workarounds, since
    # accepts_nested_attributes_for is a little...dumb.
    if assignment.submission_rule.attributes['type'] != 
         params[:assignment][:submission_rule_attributes][:type]
      # Some protective measures here to make sure we haven't been duped...
      potential_rule = 
         Module.const_get(params[:assignment][:submission_rule_attributes][:type])
      if !potential_rule.ancestors.include?(SubmissionRule)
        raise I18n.t("assignment.not_valid_submission_rule", 
          :type => params[:assignment][:submission_rule_attributes][:type])
      end
      
      assignment.submission_rule.destroy
      submission_rule = SubmissionRule.new
      # A little hack to get around Rails' protection of the "type"
      # attribute
      submission_rule.type = 
         params[:assignment][:submission_rule_attributes][:type]
      assignment.submission_rule = submission_rule
      # For some reason, when we create new rule, we can't just apply
      # the params[:assignment] hash to @assignment.attributes...we have
      # to create any new periods manually, like this:
      if !params[:assignment][:submission_rule_attributes][:periods_attributes].nil?
        assignment.submission_rule.periods_attributes = 
           params[:assignment][:submission_rule_attributes][:periods_attributes]
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

  def find_submission_for_test(grouping_id, revision_number)
    return Submission.find_by_grouping_id_and_revision_number(grouping_id, revision_number)
  end

  # Used every time a student access to the assignment page
  # It checks if the due date is passed, and if not, it
  # collect the last submission revision
  def automatically_collect_and_prepare_test(grouping, revision_number)
    # if there is no result for this grouping,
    # do nothing, because a student of the grouping
    # must run collec_and_test manually first
    return if grouping.submissions.empty?
    # Once it is time to collect files, student should'nt start to do tests
    if !grouping.assignment.submission_rule.can_collect_now?
      current_submission_used = grouping.submissions.find_by_submission_version_used(true)
      if current_submission_used.revision_number < revision_number
        new_submission = Submission.create_by_revision_number(grouping, revision_number)
        result = new_submission.result
      else
        result = current_submission_used.result
      end
    end
    return result
  end

  # Used the first time a student from a grouping wanted
  # to do test on his code
  def manually_collect_and_prepare_test(grouping, revision_number)
    # We check if it not the time to collect files
    # Once it is time to collect files, student should'nt start to do tests
    # And we create a submission with the latest revision of the svn
    if !grouping.assignment.submission_rule.can_collect_now?
      new_submission = Submission.create_by_revision_number(grouping, revision_number)
      result = new_submission.result
    end
    return result
  end

end
