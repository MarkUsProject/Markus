# Manages actions relating to editing and modifying
# groups.
class GroupsController < ApplicationController
  # Administrator
  before_action      :authorize_only_for_admin,
                     except: [:create,
                              :destroy,
                              :delete_rejected,
                              :disinvite_member,
                              :invite_member,
                              :join_group,
                              :decline_invitation,
                              ]

  before_action      :authorize_for_student,
                     only: [:create,
                            :destroy,
                            :delete_rejected,
                            :disinvite_member,
                            :invite_member,
                            :join_group,
                            :decline_invitation]

  layout 'assignment_content'

  def note_message
    @assignment = Assignment.find(params[:id])
    if params[:success]
      flash_message(:success, I18n.t('notes.create.success'))
    else
      flash_message(:error, I18n.t('notes.error'))
    end
  end

  # Group administration functions -----------------------------------------
  # Verify that all functions below are included in the authorize filter above

  def new
    assignment = Assignment.find(params[:assignment_id])
    begin
      assignment.add_group(params[:new_group_name])
      flash_now(:success, I18n.t('flash.actions.create.success',
                                 resource_name: Group.model_name.human))
    rescue Exception => e
      flash[:error] = e.message
    ensure
      head :ok
    end
  end

  def remove_group
    # When a success div exists we can return successfully removed groups
    groupings = Grouping.where(id: params[:grouping_id])
    @errors = []
    @removed_groupings = []
    Repository.get_class.update_permissions_after(only_on_request: true) do
      groupings.each do |grouping|
        grouping.student_memberships.each do |member|
          grouping.remove_member(member.id)
        end
      end
    end
    # TODO: return errors through request
    groupings.each do |grouping|
      if grouping.has_submission?
        @errors.push(grouping.group.group_name)
      else
        grouping.delete_grouping
        @removed_groupings.push(grouping)
      end
    end
    head :ok
  end

  def rename_group
    @assignment = Assignment.find(params[:assignment_id])
    # group_id is really the grouping_id, this is due to rails routing
    @grouping = Grouping.find(params[:id])
    @group = @grouping.group

    # Checking if a group with this name already exists
    if (@groups = Group.where(group_name: params[:new_groupname]).first)
       existing = true
       groupexist_id = @groups.id
    end

    unless existing
      # We update the group_name
      @group.group_name = params[:new_groupname]
      if @group.save
        flash_now(:success, I18n.t('flash.actions.update.success',
                                   resource_name: Group.human_attribute_name(:group_name)))
      end
    else

      # We link the grouping to the group already existing

      # We verify there is no other grouping linked to this group on the
      # same assignement
      params[:groupexist_id] = groupexist_id
      params[:assignment_id] = @assignment.id

      if Grouping.where(assignment_id: @assignment.id, group_id: groupexist_id)
                 .to_a
        flash[:error] = I18n.t('groups.group_name_already_in_use')
      else
        @grouping.update_attribute(:group_id, groupexist_id)
      end
    end
    head :ok
  end

  def valid_grouping
    assignment = Assignment.find(params[:assignment_id])
    grouping = Grouping.find(params[:grouping_id])
    grouping.validate_grouping
    head :ok
  end

  def invalid_grouping
    assignment = Assignment.find(params[:assignment_id])
    grouping = Grouping.find(params[:grouping_id])
    grouping.invalidate_grouping
    head :ok
  end

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @clone_assignments = Assignment.where(vcs_submit: true)
                                   .where.not(id: @assignment.id)
                                   .order(:id)

    respond_to do |format|
      format.html
      format.json do
        render json: @assignment.all_grouping_data
      end
    end
  end

  def assign_scans
    @assignment = Assignment.find(params[:assignment_id])
    if params.has_key?(:grouping)
      next_grouping = Grouping.find(params[:grouping])
    else
      next_grouping = Grouping.get_assign_scans_grouping(@assignment)
    end
    if next_grouping.nil?
      redirect_to(:back)
      return
    end
    names = next_grouping.non_rejected_student_memberships.map do |u|
      u.user.first_name + ' ' + u.user.last_name
    end
    num_valid = @assignment.get_num_valid
    num_total = @assignment.get_num_assigned
    if num_valid == num_total
      flash_message(:success, t('groups.done_assign'))
    end
    @data = {
      group_name: next_grouping.group.group_name,
      grouping_id: next_grouping.id,
      students: names,
      num_total: num_total,
      num_valid: num_valid
    }
    next_file = next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf')
    unless next_file.nil?
      @data[:filelink] = download_assignment_groups_path(
        select_file_id: next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf').id,
        show_in_browser: true )
    end
  end

  def get_names
    names = Student
              .select(:id, :id_number, :user_name, "CONCAT(first_name,' ',last_name) AS label, CONCAT(first_name,' ',last_name) AS value")
              .where("(lower(first_name) like ? OR lower(last_name) like ? OR lower(user_name) like ? OR id_number like ?) AND users.id NOT IN (?)",
                     "#{params[:term].downcase}%", "#{params[:term].downcase}%", "#{params[:term].downcase}%", "#{params[:term]}%",
                     Membership.select(:user_id).joins(:grouping).where("groupings.assignment_id = ?", params[:assignment]));
    render json: names
  end

  def assign_student_and_next
    @grouping = Grouping.find(params[:g_id])
    @assignment = @grouping.assignment
    unless params[:skip]
      # if the user has selected a name from the dropdown, s_id is set
      if params[:s_id].present?
        student = Student.find(params[:s_id])
      end
      # if the user has typed in the whole name without select, or if they typed a name different from the select s_id
      if student.nil? || (student.first_name + ' ' + student.last_name) != params[:names]
        student = Student.where('lower(CONCAT(first_name, \' \', last_name)) like ? OR lower(CONCAT(last_name, \' \', first_name)) like ?',
                                 params[:names].downcase, params[:names].downcase).first
      end
      StudentMembership
        .find_or_create_by(user: student, grouping: @grouping, membership_status: StudentMembership::STATUSES[:inviter])
    end
    next_grouping
  end

  def next_grouping
    if params[:a_id].present?
      @assignment = Assignment.find(params[:a_id])
    end
    next_grouping = Grouping.get_assign_scans_grouping(@assignment)
    names = next_grouping.non_rejected_student_memberships.map do |u|
      u.user.first_name + ' ' + u.user.last_name
    end
    num_valid = @assignment.get_num_valid
    num_total = @assignment.get_num_assigned
    if num_valid == num_total
      flash_message(:success, t('groups.done_assign'))
    end
    if !@grouping.nil? && next_grouping.id == @grouping.id
      render json: {
        grouping_id: next_grouping.id,
        students: names,
        num_total: num_total,
        num_valid: num_valid
      }
    else
      data = {
        group_name: next_grouping.group.group_name,
        grouping_id: next_grouping.id,
        students: names,
        num_total: num_total,
        num_valid: num_valid
      }
      next_file = next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf')
      unless next_file.nil?
          data[:filelink] = download_assignment_groups_path(
          select_file_id: next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf').id,
          show_in_browser: true )
      end
      render json: data
    end
  end

  # Allows the user to upload a csv file listing groups. If group_name is equal
  # to the only member of a group and the assignment is configured with
  # allow_web_subits == false, the student's username will be used as the
  # repository name. If MarkUs is not repository admin, the repository name as
  # specified by the second field will be used instead.
  def csv_upload
    if params[:group] && params[:group][:grouplist]
      file = params[:group][:grouplist]
      encoding = params[:encoding]
      @assignment = Assignment.find(params[:assignment_id])
      # Transaction allows us to potentially roll back if something
      # really bad happens.
      ApplicationRecord.transaction do
        # Loop over each row, which lists the members to be added to the group.
        result = MarkusCSV.parse(file.read, encoding: encoding) do |row|
          @assignment.add_csv_group(row)
        end
        unless result[:invalid_lines].empty?
          flash_message(:error, result[:invalid_lines])
        end
        unless result[:valid_lines].empty?
          flash_message(:success, result[:valid_lines])
        end
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
    end
    redirect_to action: 'index', id: params[:id]
  end

  def create_groups_when_students_work_alone
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.group_max == 1
      @current_job = CreateIndividualGroupsForAllStudentsJob.perform_later @assignment
      session[:job_id] = @current_job.job_id
    end

    respond_to do |format|
      format.js { render 'shared/_poll_job.js.erb' }
    end
  end

  def download
    file = SubmissionFile.find(params[:select_file_id])
    file_contents = file.retrieve_file

    filename = file.filename
    send_data file_contents, filename: filename
  end

  def download_grouplist
    assignment = Assignment.find(params[:assignment_id])
    groupings = assignment.groupings.includes(:group,
                                              student_memberships: [:user])

    file_out = MarkusCSV.generate(groupings) do |grouping|
      # csv format is group_name, repo_name, user1_name, user2_name, ... etc
      [grouping.group.group_name, grouping.group.repo_name].concat(
        grouping.student_memberships.map do |member|
          member.user.user_name
        end
      )
    end

    send_data(file_out,
              type: 'text/csv',
              filename: "#{assignment.short_identifier}_group_list.csv",
              disposition: 'attachment')
  end

  def use_another_assignment_groups
    target_assignment = Assignment.find(params[:assignment_id])
    source_assignment = Assignment.find(params[:clone_assignment_id])

    if source_assignment.nil?
      flash_message(:warning, t('groups.csv.could_not_find_source'))
    elsif target_assignment.nil?
      flash_message(:warning, t('groups.csv.could_not_find_target'))
    else
      # Clone the groupings
      clone_warnings = target_assignment.clone_groupings_from(source_assignment.id)
      unless clone_warnings.empty?
        clone_warnings.each { |w| flash_message(:warning, w) }
      end
    end

    redirect_back(fallback_location: root_path)
  end

  def join_group
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @user.join(@grouping.id)
    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{@user.user_name}' joined group '#{@grouping.group.group_name}'" +
                   '(accepted invitation).')
    redirect_to student_interface_assignment_path(params[:id])
  end

  def decline_invitation
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @grouping.decline_invitation(@user)
    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{@user.user_name}' declined invitation for group '" +
                   "#{@grouping.group.group_name}'.")
    redirect_to student_interface_assignment_path(params[:id])
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @student = @current_user
    m_logger = MarkusLogger.instance
    begin
      # We do not allow group creations by students after the due date
      # and the grace period for an assignment
      if @assignment.past_collection_date?(@student.section)
        raise I18n.t('create_group.fail.due_date_passed')
      end
      if !@assignment.student_form_groups ||
        @assignment.invalid_override
        raise I18n.t('create_group.fail.not_allow_to_form_groups')
      end
      if @student.has_accepted_grouping_for?(@assignment.id)
        raise I18n.t('create_group.fail.already_have_a_group')
      end
      if params[:workalone]
        if @assignment.group_min != 1
          raise I18n.t('create_group.fail.can_not_work_alone',
                       group_min: @assignment.group_min)
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
    redirect_to student_interface_assignment_path(@assignment.id)
  end

  def destroy
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = @current_user.accepted_grouping_for(@assignment.id)
    m_logger = MarkusLogger.instance
    begin
      if @grouping.nil?
        raise I18n.t('create_group.fail.do_not_have_a_group')
      end
      # If grouping is not deletable for @current_user for whatever reason, fail.
      unless @grouping.deletable_by?(@current_user)
        raise I18n.t('groups.cant_delete')
      end
      # Note: This error shouldn't be raised normally, as the student shouldn't
      # be able to try to delete the group in this case.
      if @grouping.has_submission?
        raise I18n.t('groups.cant_delete_already_submitted')
      end

      Repository.get_class.update_permissions_after(only_on_request: true) do
        @grouping.student_memberships.each do |member|
          @grouping.remove_member(member.id)
        end
      end

      @grouping.destroy
      flash_message(:success, I18n.t('flash.actions.destroy.success', resource_name: Group.model_name.human))
      m_logger.log("Student '#{current_user.user_name}' deleted group '" +
                     "#{@grouping.group.group_name}'.", MarkusLogger::INFO)

    rescue RuntimeError => e
      flash[:fail_notice] = e.message
      if @grouping.nil?
        m_logger.log(
          'Failed to delete group, since no accepted group for this user existed.' +
            "User: '#{current_user.user_name}', Error: '#{e.message}'.", MarkusLogger::ERROR)
      else
        m_logger.log("Failed to delete group '#{@grouping.group.group_name}'. User: '" +
                       "#{current_user.user_name}', Error: '#{e.message}'.", MarkusLogger::ERROR)
      end
    end
    redirect_to student_interface_assignment_path(params[:id])
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
    MarkusLogger.instance
    @grouping.invite(to_invite)
    flash[:fail_notice] = @grouping.errors['base']
    if flash[:fail_notice].blank?
      flash_message(:success, I18n.t('invite_student.success'))
    end
    redirect_to student_interface_assignment_path(@assignment.id)
  end

  # Called by clicking the cancel link in the student's interface
  # i.e. cancels invitations
  def disinvite_member
    assignment = Assignment.find(params[:id])
    membership = StudentMembership.find(params[:membership])
    disinvited_student = membership.user
    membership.delete
    membership.save
    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{current_user.user_name}' cancelled invitation for " +
                   "'#{disinvited_student.user_name}'.")
    flash_message(:success, I18n.t('student.member_disinvited'))
    redirect_to student_interface_assignment_path(assignment.id)
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
    redirect_to student_interface_assignment_path(params[:id])
  end

  # These actions act on all currently selected students & groups
  def global_actions
    assignment = Assignment.includes([{
                                      groupings: [{
                                          student_memberships: :user,
                                          ta_memberships: :user},
                                        :group]}])
                            .find(params[:assignment_id])
    action = params[:global_actions]
    grouping_ids = params[:groupings]
    student_ids = params[:students]
    students_to_remove = params[:students_to_remove]

    # Start exception catching. If an exception is raised,
    # return http response code of 400 (bad request) along
    # the error string. The front-end should get it and display
    # the message in an error div.
    begin
      # Every action should have a grouping associated with it.
      # (except for unassign)
      # check_for_groupings makes sure there is at least one and
      # raises an error if there isn't.
      groupings = Grouping.where(id: grouping_ids)
      unless action == 'unassign'
        check_for_groupings(groupings)
      end

      # Students are only needed for assign/unassign so don't
      # need to check.
      students = Student.where(id: student_ids)

      case params[:global_actions]
      when 'delete'
        delete_groupings(groupings)
      when 'invalid'
        invalidate_groupings(groupings)
      when 'valid'
        validate_groupings(groupings)
      when 'assign'
        add_members(students, groupings, assignment)
      when 'unassign'
        remove_members(students_to_remove, assignment)
      end
      head :ok
    rescue => e
      flash_now(:error, e.message)
      head 400
    end
  end

  private
  # These methods are called through global actions.

  # Check that there is at least one grouping selected
  def check_for_groupings(groupings)
    if groupings.blank?
      raise I18n.t('groups.select_a_group')
    end
  end

  # Given a list of grouping, sets their group status to invalid if possible
  def invalidate_groupings(groupings)
    groupings.each do |grouping|
     grouping.invalidate_grouping
    end
  end

  # Given a list of grouping, sets their group status to valid if possible
  def validate_groupings(groupings)
    groupings.each do |grouping|
      grouping.validate_grouping
    end
  end

  # Deletes the given list of groupings if possible. Removes each member first.
  def delete_groupings(groupings)
    # If any groupings have a submission raise an error.
    if groupings.any?(&:has_submission?)
      raise I18n.t('groups.could_not_delete') # should add names of grouping we could not delete
    else
      # Remove each student from every group.
      Repository.get_class.update_permissions_after(only_on_request: true) do
        groupings.each do |grouping|
          grouping.student_memberships.each do |mem|
            grouping.remove_member(mem.id)
          end
          grouping.delete_grouping
        end
      end
    end
  end

  # Adds students to grouping. `groupings` should be an array with
  # only one element, which is the grouping that is supposed to be
  # added to.
  def add_members(students, groupings, assignment)
    if groupings.size != 1
      raise I18n.t('groups.select_only_one_group')
    end
    if students.blank?
      raise I18n.t('groups.select_a_student')
    end

    grouping = groupings.first

    students.each do |student|
      add_member(student, grouping, assignment)
    end

    # Generate warning if the number of people assigned to a group exceeds
    # the maximum size of a group
    students_in_group = grouping.student_membership_number
    group_name = grouping.group.group_name
    if assignment.student_form_groups
      if students_in_group > assignment.group_max
        raise I18n.t('assignment.group.assign_over_limit', group: group_name)
      end
    end
  end

  # Adds the student given in student_id to the grouping given in grouping
  def add_member(student, grouping, assignment)
    set_membership_status = grouping.student_memberships.empty? ?
          StudentMembership::STATUSES[:inviter] :
          StudentMembership::STATUSES[:accepted]
    @messages = []
    @bad_user_names = []

    if student.hidden
      raise I18n.t('add_student.fail.hidden', user_name: student.user_name)
    end
    if student.has_accepted_grouping_for?(assignment.id)
      raise I18n.t('add_student.fail.already_grouped',
        user_name: student.user_name)
    end
    membership_count = grouping.student_memberships.length
    grouping.invite(student.user_name, set_membership_status, true)
    grouping.reload

    # Report success only if # of memberships increased
    if membership_count < grouping.student_memberships.length
      @messages.push(I18n.t('add_student.success',
          user_name: student.user_name))
    else # something clearly went wrong
      raise I18n.t('add_student.fail.general',
        user_name: student.user_name)
    end

    # Only the first student should be the "inviter"
    # (and only update this if it succeeded)
    set_membership_status = StudentMembership::STATUSES[:accepted]

    # Generate a warning if a member is added to a group and they
    # have fewer grace days credits than already used by that group
    if student.remaining_grace_credits < grouping.grace_period_deduction_single
      @warning_grace_day = I18n.t('assignment.group.grace_day_over_limit',
        group: grouping.group.group_name)
    end

    grouping.reload
  end

  # Removes the students contained in params from the groupings given
  # in groupings.
  # This is meant to be called with the params from global_actions, and for
  # each student to delete it will have a parameter
  # of the form "groupid_studentid"
  # This code is possibly not safe. (should add error checking)
  def remove_members(member_ids_to_remove, assignment)
    members_to_remove = Student.where(user_name: member_ids_to_remove)
    Repository.get_class.update_permissions_after(only_on_request: true) do
      members_to_remove.each do |member|
        grouping = member.accepted_grouping_for(assignment.id)
        membership = grouping.student_memberships.find_by_user_id(member.id)
        remove_member(membership, grouping, assignment)
      end
    end
  end

  # Removes the given student membership from the given grouping
  def remove_member(membership, grouping, assignment)
    grouping.remove_member(membership.id)
    grouping.reload
  end
end
