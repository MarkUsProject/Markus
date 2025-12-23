# Manages actions relating to editing and modifying
# groups.
class GroupsController < ApplicationController
  # Administrator
  before_action { authorize! }
  layout 'assignment_content'

  content_security_policy only: [:assign_scans] do |p|
    p.img_src :self, :blob
  end

  # Group administration functions -----------------------------------------
  # Verify that all functions below are included in the authorize filter above

  def new
    assignment = Assignment.find(params[:assignment_id])
    begin
      assignment.add_group(params[:new_group_name])
      flash_now(:success, I18n.t('flash.actions.create.success',
                                 resource_name: Group.model_name.human))
    rescue StandardError => e
      flash_now(:error, e.message)
    ensure
      head :ok
    end
  end

  def remove_group
    # When a success div exists we can return successfully removed groups
    groupings = Grouping.where(id: params[:grouping_id])
    errors = []
    @removed_groupings = []
    Repository.get_class.update_permissions_after(only_on_request: true) do
      groupings.each do |grouping|
        grouping.student_memberships.each do |member|
          grouping.remove_member(member.id)
        end
      end
    end
    groupings.each do |grouping|
      if grouping.has_submission?
        errors.push(grouping.group.group_name)
      else
        grouping.delete_grouping
        @removed_groupings.push(grouping)
      end
    end
    if errors.any?
      err_groups = errors.join(', ')
      flash_message(:error, I18n.t('groups.delete_group_has_submission') + err_groups)
    end
    head :ok
  end

  def rename_group
    @grouping = record
    @assignment = record.assignment
    @group = @grouping.group

    # Checking if a group with this name already exists
    if (@existing_group = current_course.groups.where(group_name: params[:new_groupname]).first)
      existing = true
      groupexist_id = @existing_group.id
    end

    if existing

      # We link the grouping to the group already existing

      # We verify there is no other grouping linked to this group on the
      # same assignement
      params[:groupexist_id] = groupexist_id
      params[:assignment_id] = @assignment.id

      if Grouping.exists?(assessment_id: @assignment.id, group_id: groupexist_id)
        flash_now(:error, I18n.t('groups.group_name_already_in_use'))
      elsif @grouping.has_submitted_files? || @grouping.has_non_empty_submission?
        flash_now(:error, I18n.t('groups.group_name_already_in_use_diff_assignment'))
      else
        @grouping.update_attribute(:group_id, groupexist_id)
      end
    else
      # We update the group_name
      @group.group_name = params[:new_groupname]
      if @group.save
        flash_now(:success, I18n.t('flash.actions.update.success',
                                   resource_name: Group.human_attribute_name(:group_name)))
      end
    end
    head :ok
  end

  def valid_grouping
    # TODO: make this a member route in a new GroupingsController
    assignment = Assignment.find(params[:assignment_id])
    grouping = assignment.groupings.find(params[:grouping_id])
    grouping.validate_grouping
    head :ok
  end

  def invalid_grouping
    # TODO: make this a member route in a new GroupingsController
    assignment = Assignment.find(params[:assignment_id])
    grouping = assignment.groupings.find(params[:grouping_id])
    grouping.invalidate_grouping
    head :ok
  end

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @clone_assignments = current_course.assignments
                                       .joins(:assignment_properties)
                                       .where(assignment_properties: { vcs_submit: true })
                                       .where.not(id: @assignment.id)
                                       .order(:id)

    respond_to do |format|
      format.html
      format.json do
        render json: @assignment.all_grouping_data.merge(
          clone_assignments: @clone_assignments.as_json(only: [:id, :short_identifier])
        )
      end
    end
  end

  def assign_scans
    # TODO: make this a member route in a new GroupingsController
    @assignment = Assignment.find(params[:assignment_id])
    if params.key?(:grouping_id)
      next_grouping = @assignment.groupings.find(params[:grouping_id])
    else
      next_grouping = Grouping.get_assign_scans_grouping(@assignment)
    end
    if next_grouping&.current_submission_used.nil?
      if @assignment.groupings.left_outer_joins(:current_submission_used).where('submissions.id': nil).any?
        flash_message(:warning, I18n.t('exam_templates.assign_scans.not_all_submissions_collected'))
      end
      redirect_back(fallback_location: course_assignment_groups_path(current_course, @assignment))
      return
    end
    names = next_grouping.non_rejected_student_memberships.map do |u|
      u.user.display_name
    end
    num_valid = @assignment.get_num_valid
    num_total = @assignment.groupings.size
    if num_valid == num_total
      flash_message(:success, t('exam_templates.assign_scans.done'))
    end
    # Get OCR match data and suggestions if available
    ocr_match = OcrMatchService.get_match(next_grouping.id)
    ocr_suggestions = ocr_match ? OcrMatchService.get_suggestions(next_grouping.id, current_course.id) : []

    @data = {
      group_name: next_grouping.group.group_name,
      grouping_id: next_grouping.id,
      students: names,
      num_total: num_total,
      num_valid: num_valid,
      ocr_match: ocr_match,
      ocr_suggestions: format_ocr_suggestions(ocr_suggestions)
    }
    next_file = next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf')
    if next_file.nil?
      flash_message(:warning, I18n.t('exam_templates.assign_scans.no_cover_page'))
    else
      @data[:filelink] = download_course_assignment_groups_path(
        current_course, @assignment,
        select_file_id: next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf').id,
        show_in_browser: true
      )
    end
  end

  def get_names
    names = current_course.students
                          .joins(:user)
                          .where("(lower(first_name) like ? OR
                                   lower(last_name) like ? OR
                                   lower(user_name) like ? OR
                                   id_number like ?) AND roles.hidden IN (?) AND roles.id NOT IN (?)",
                                 "#{ApplicationRecord.sanitize_sql_like(params[:term].downcase)}%",
                                 "#{ApplicationRecord.sanitize_sql_like(params[:term].downcase)}%",
                                 "#{ApplicationRecord.sanitize_sql_like(params[:term].downcase)}%",
                                 "#{ApplicationRecord.sanitize_sql_like(params[:term])}%",
                                 params[:display_inactive] == 'true' ? [true, false] : [false],
                                 Membership.select(:role_id)
                                           .joins(:grouping)
                                           .where(groupings: { assessment_id: params[:assignment_id] }))
                          .pluck_to_hash(:id, 'users.id_number', 'users.user_name',
                                         'users.first_name', 'users.last_name', 'roles.hidden')

    names = names.map do |h|
      inactive = h['roles.hidden'] ? I18n.t('student.inactive') : ''
      { id: h[:id],
        id_number: h['users.id_number'],
        user_name: h['users.user_name'],
        value: "#{h['users.first_name']} #{h['users.last_name']}#{inactive}" }
    end
    render json: names
  end

  def assign_student_and_next
    # TODO: make this a member route in a new GroupingsController
    @grouping = Grouping.joins(:assignment).where('assessments.course_id': current_course.id).find(params[:g_id])
    @assignment = @grouping.assignment
    unless params[:skip]
      # if the user has selected a name from the dropdown, s_id is set
      if params[:s_id].present?
        student = current_course.students.find(params[:s_id])
      end
      replace_pattern = /#{Regexp.escape(I18n.t('student.inactive'))}\s*$/
      student_name = params[:names].sub(replace_pattern, '').strip

      # if the user has typed in the whole name without select, or if they typed a name different from the select s_id
      if student.nil? || "#{student.first_name} #{student.last_name}" != student_name
        student = current_course.students.joins(:user).where(
          'lower(CONCAT(first_name, \' \', last_name)) like ? OR lower(CONCAT(last_name, \' \', first_name)) like ?',
          ApplicationRecord.sanitize_sql_like(student_name.downcase),
          ApplicationRecord.sanitize_sql_like(student_name.downcase)
        ).first
      end
      if student.nil?
        flash_message(:error, t('exam_templates.assign_scans.student_not_found', name: params[:names]))
        head :not_found
        return
      end
      StudentMembership
        .find_or_create_by(role: student, grouping: @grouping, membership_status: StudentMembership::STATUSES[:inviter])
      # Clear OCR match data after successful assignment
      OcrMatchService.clear_match(@grouping.id)
    end
    next_grouping
  end

  def next_grouping
    # TODO: is this actually a route that is called from anywhere or just a helper method?
    if params[:a_id].present?
      @assignment = Assignment.find(params[:a_id])
    end
    next_grouping = Grouping.get_assign_scans_grouping(@assignment, params[:g_id])
    if next_grouping.nil?
      head :not_found
      return
    end
    names = next_grouping.non_rejected_student_memberships.map do |u|
      u.user.display_name
    end
    num_valid = @assignment.get_num_valid
    num_total = @assignment.groupings.size
    if num_valid == num_total
      flash_message(:success, t('exam_templates.assign_scans.done'))
    end
    # Get OCR match data and suggestions if available
    ocr_match = OcrMatchService.get_match(next_grouping.id)
    ocr_suggestions = ocr_match ? OcrMatchService.get_suggestions(next_grouping.id, current_course.id) : []

    if !@grouping.nil? && next_grouping.id == @grouping.id
      render json: {
        grouping_id: next_grouping.id,
        students: names,
        num_total: num_total,
        num_valid: num_valid,
        ocr_match: ocr_match,
        ocr_suggestions: format_ocr_suggestions(ocr_suggestions)
      }
    else
      data = {
        group_name: next_grouping.group.group_name,
        grouping_id: next_grouping.id,
        students: names,
        num_total: num_total,
        num_valid: num_valid,
        ocr_match: ocr_match,
        ocr_suggestions: format_ocr_suggestions(ocr_suggestions)
      }
      next_file = next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf')
      unless next_file.nil?
        data[:filelink] = download_course_assignment_groups_path(
          current_course,
          @assignment,
          select_file_id: next_grouping.current_submission_used.submission_files.find_by(filename: 'COVER.pdf').id,
          show_in_browser: true
        )
      end
      render json: data
    end
  end

  # Allows the user to upload a csv file listing groups. If group_name is equal
  # to the only member of a group and the assignment is configured with
  # allow_web_subits == false, the student's username will be used as the
  # repository name. If MarkUs is not repository admin, the repository name as
  # specified by the second field will be used instead.
  def upload
    assignment = Assignment.find(params[:assignment_id])
    begin
      data = process_file_upload(['.csv'])
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      group_rows = []
      result = MarkusCsv.parse(data[:contents], encoding: data[:encoding]) do |row|
        next if row.blank?
        raise CsvInvalidLineError if row[0].blank?

        group_rows << row.compact_blank
      end

      if result[:invalid_lines].empty?
        @current_job = CreateGroupsJob.perform_later assignment, group_rows
        session[:job_id] = @current_job.job_id
      else
        flash_message(:error, result[:invalid_lines])
      end
    end
    redirect_to course_assignment_groups_path(current_course, assignment)
  end

  def create_groups_when_students_work_alone
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.group_max == 1
      # data is a list of lists containing: [[group_name, group_member], ...]
      data = current_course.students
                           .joins(:user)
                           .where(hidden: false)
                           .pluck('users.user_name')
                           .map { |user_name| [user_name, user_name] }
      @current_job = CreateGroupsJob.perform_later @assignment, data
      session[:job_id] = @current_job.job_id
    end

    respond_to do |format|
      format.js { render 'shared/_poll_job' }
    end
  end

  def download
    # TODO: make this a member route in a new SubmissionFileController
    file = SubmissionFile.find(params[:select_file_id])
    # TODO: remove this check once this is moved to a new SubmissionFileController
    return page_not_found unless file.course == current_course

    file_contents = file.retrieve_file

    filename = file.filename
    send_data_download file_contents, filename: filename
  end

  def download_grouplist
    assignment = Assignment.find(params[:assignment_id])
    groupings = assignment.groupings.includes(:group, student_memberships: :role)

    file_out = MarkusCsv.generate(groupings) do |grouping|
      # csv format is group_name, repo_name, user1_name, user2_name, ... etc
      [grouping.group.group_name].concat(
        grouping.student_memberships.map do |member|
          member.role.user_name
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

    return head :unprocessable_content if target_assignment.course != source_assignment.course

    if source_assignment.nil?
      flash_message(:warning, t('groups.clone_warning.could_not_find_source'))
    elsif target_assignment.nil?
      flash_message(:warning, t('groups.clone_warning.could_not_find_target'))
    else
      # Clone the groupings
      clone_warnings = target_assignment.clone_groupings_from(source_assignment.id)
      unless clone_warnings.empty?
        clone_warnings.each { |w| flash_message(:warning, w) }
      end
    end

    redirect_back(fallback_location: root_path)
  end

  def accept_invitation
    # TODO: make this a member route in a new GroupingsController
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = @assignment.groupings.find(params[:grouping_id])
    begin
      current_role.join(@grouping)
    rescue ActiveRecord::RecordInvalid, RuntimeError => e
      flash_message(:error, e.message)
      status = :unprocessable_content
    else
      m_logger = MarkusLogger.instance
      m_logger.log("Student '#{current_role.user_name}' joined group " \
                   "'#{@grouping.group.group_name}'(accepted invitation).")
      status = :found
    end
    redirect_to course_assignment_path(current_course, @assignment), status: status
  end

  def decline_invitation
    # TODO: make this a member route in a new GroupingsController
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = @assignment.groupings.find(params[:grouping_id])
    begin
      @grouping.decline_invitation(current_role)
    rescue RuntimeError => e
      flash_message(:error, e.message)
      status = :unprocessable_content
    else
      m_logger = MarkusLogger.instance
      m_logger.log("Student '#{current_role.user_name}' declined invitation for group '#{@grouping.group.group_name}'.")
      status = :found
    end
    redirect_to course_assignment_path(current_course, @assignment), status: status
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @student = current_role
    m_logger = MarkusLogger.instance
    begin
      return unless flash_allowance(:error, allowance_to(:create_group?, @assignment)).value
      if params[:workalone]
        return unless flash_allowance(:error, allowance_to(:work_alone?, @assignment)).value
        @student.create_group_for_working_alone_student(@assignment.id)
      else
        return unless flash_allowance(:error, allowance_to(:autogenerate_group_name?, @assignment)).value
        @student.create_autogenerated_name_group(@assignment)
      end
      m_logger.log("Student '#{@student.user_name}' created group.", MarkusLogger::INFO)
    rescue RuntimeError => e
      flash_message(:error, e.message)
      m_logger.log("Failed to create group. User: '#{@student.user_name}', Error: '#{e.message}'.", MarkusLogger::ERROR)
    end
  ensure
    redirect_to course_assignment_path(current_course, @assignment)
  end

  def destroy
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = current_role.accepted_grouping_for(@assignment.id)
    m_logger = MarkusLogger.instance
    if @grouping.nil?
      m_logger.log('Failed to delete group, since no accepted group for this user existed.' \
                   "User: '#{current_role.user_name}'.", MarkusLogger::ERROR)
      flash_message(:error, I18n.t('groups.destroy.errors.do_not_have_a_group'))
      redirect_to course_assignment_path(current_course, @assignment)
      return
    end
    if flash_allowance(:error, allowance_to(:destroy?, @grouping)).value
      begin
        Repository.get_class.update_permissions_after(only_on_request: true) do
          @grouping.student_memberships.each do |member|
            @grouping.remove_member(member.id)
          end
        end
        @grouping.destroy
        flash_message(:success, I18n.t('flash.actions.destroy.success', resource_name: Group.model_name.human))
        m_logger.log("Student '#{current_role.user_name}' deleted group '" \
                     "#{@grouping.group.group_name}'.", MarkusLogger::INFO)
      rescue RuntimeError => e
        m_logger.log("Failed to delete group '#{@grouping.group.group_name}'. User: '" \
                     "#{current_role.user_name}', Error: '#{e.message}'.", MarkusLogger::ERROR)
      end
    end
    redirect_to course_assignment_path(current_course, @assignment)
  end

  def invite_member
    @assignment = Assignment.find(params[:assignment_id])

    @grouping = current_role.accepted_grouping_for(@assignment.id)
    if @grouping.nil?
      flash_message(:error,
                    I18n.t('groups.invite_member.errors.need_to_create_group'))
      redirect_to course_assignment_path(@course, @assignment)
      return
    end
    if flash_allowance(:error, allowance_to(:invite_member?, @grouping)).value
      to_invite = params[:invite_member].split(',')
      errors = @grouping.invite(to_invite)
      if errors.blank?
        to_invite.each do |i|
          i = i.strip
          invited_user = current_course.students.joins(:user).find_by('users.user_name': i)
          if invited_user&.receives_invite_emails?
            NotificationMailer.with(inviter: current_role,
                                    invited: invited_user,
                                    grouping: @grouping).grouping_invite_email.deliver_later
          end
        end
        flash_message(:success, I18n.t('groups.invite_member.success'))
      else
        flash_message(:error, errors.join(' '))
      end
    end
    redirect_to course_assignment_path(current_course, @assignment.id)
  end

  # Deletes pending invitations
  def disinvite_member
    assignment = Assignment.find(params[:assignment_id])
    membership = assignment.student_memberships.find(params[:membership])
    authorized = flash_allowance(:error, allowance_to(:disinvite_member?,
                                                      membership.grouping,
                                                      context: { membership: membership })).value
    if authorized
      disinvited_student = membership.role
      membership.destroy
      m_logger = MarkusLogger.instance
      m_logger.log("Student '#{current_role.user_name}' cancelled invitation for '#{disinvited_student.user_name}'.")
      flash_message(:success, I18n.t('groups.members.member_disinvited'))
    end
    status = authorized ? :found : :forbidden
    redirect_to course_assignment_path(current_course, assignment.id), status: status
  end

  # Deletes memberships which have been declined by students
  def delete_rejected
    @assignment = Assignment.find(params[:assignment_id])
    membership = @assignment.student_memberships.find(params[:membership])
    grouping = membership.grouping
    authorized = flash_allowance(:error,
                                 allowance_to(:delete_rejected?, grouping, context: { membership: membership })).value
    membership.destroy if authorized
    status = authorized ? :found : :forbidden
    redirect_to course_assignment_path(current_course, @assignment), status: status
  end

  # These actions act on all currently selected students & groups
  def global_actions
    assignment = Assignment.includes([{ groupings: [{ student_memberships: :role, ta_memberships: :role }, :group] }])
                           .find(params[:assignment_id])
    grouping_ids = params[:groupings]
    student_ids = params[:students]
    students_to_remove = params[:students_to_remove]

    # Start exception catching. If an exception is raised,
    # return http response code of 400 (bad request) along
    # the error string. The front-end should get it and display
    # the message in an error div.
    begin
      groupings = Grouping.where(id: grouping_ids)
      check_for_groupings(groupings)

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
        remove_members(students_to_remove, groupings)
      end
      head :ok
    rescue StandardError => e
      flash_now(:error, e.message)
      head :bad_request
    end
  end

  def download_starter_file
    assignment = Assignment.find(params[:assignment_id])
    grouping = current_role.accepted_grouping_for(assignment.id)

    authorize! grouping, with: GroupingPolicy

    grouping.reset_starter_file_entries if grouping.starter_file_changed

    zip_name = "#{assignment.short_identifier}-starter-files-#{current_role.user_name}"
    zip_path = File.join('tmp', zip_name + '.zip')
    FileUtils.rm_rf zip_path
    Zip::File.open(zip_path, create: true) do |zip_file|
      grouping.starter_file_entries.reload.each { |entry| entry.add_files_to_zip_file(zip_file) }
    end
    send_file zip_path, filename: File.basename(zip_path)
  end

  def populate_repo_with_starter_files
    assignment = Assignment.find(params[:assignment_id])
    grouping = current_role.accepted_grouping_for(assignment.id)

    authorize! grouping, with: GroupingPolicy

    grouping.reset_starter_file_entries if grouping.starter_file_changed

    grouping.access_repo do |repo|
      txn = repo.get_transaction(current_role.user_name)
      grouping.starter_file_entries.reload.each { |entry| entry.add_files_to_repo(repo, txn) }
      if repo.commit(txn)
        flash_message(:success, I18n.t('assignments.starter_file.populate_repo_success'))
      else
        flash_message(:error, I18n.t('assignments.starter_file.populate_repo_error'))
      end
    end
    redirect_to course_assignment_path(current_course, assignment)
  end

  def auto_match
    assignment = Assignment.find(params[:assignment_id])
    grouping_ids = params[:groupings]
    exam_template_id = params[:exam_template_id]
    groupings = assignment.groupings.find(grouping_ids)
    exam_template = assignment.exam_templates.find(exam_template_id)

    @current_job = AutoMatchJob.perform_later groupings, exam_template
    session[:job_id] = @current_job.job_id

    respond_to do |format|
      format.js { render 'shared/_poll_job' }
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
    groupings.each(&:invalidate_grouping)
  end

  # Given a list of grouping, sets their group status to valid if possible
  def validate_groupings(groupings)
    groupings.each(&:validate_grouping)
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
    if assignment.student_form_groups && (students_in_group > assignment.group_max)
      raise I18n.t('groups.assign_over_limit', group: group_name)
    end
  end

  # Adds the student given in student_id to the grouping given in grouping
  def add_member(student, grouping, assignment)
    set_membership_status = if grouping.student_memberships.empty?
                              StudentMembership::STATUSES[:inviter]
                            else
                              StudentMembership::STATUSES[:accepted]
                            end
    @bad_user_names = []

    if student.has_accepted_grouping_for?(assignment.id)
      raise I18n.t('groups.invite_member.errors.already_grouped', user_name: student.user_name)
    end
    errors = grouping.invite(student.user_name, set_membership_status, invoked_by_instructor: true)
    grouping.reload

    if errors.present?
      raise errors.join(' ')
    end

    # Generate a warning if a member is added to a group and they
    # have fewer grace days credits than already used by that group
    if student.remaining_grace_credits < grouping.grace_period_deduction_single
      @warning_grace_day = I18n.t('groups.grace_day_over_limit', group: grouping.group.group_name)
    end

    grouping.reload
  end

  # Removes the students with user names in +member_names+ from the
  # groupings in +groupings+. This removes any type of student membership
  # even pending memberships.
  #
  # This is meant to be called with the params from global_actions
  def remove_members(member_names, groupings)
    members_to_remove = current_course.students.joins(:user).where('users.user_name': member_names)
    Repository.get_class.update_permissions_after(only_on_request: true) do
      members_to_remove.each do |member|
        groupings.each do |grouping|
          membership = grouping.student_memberships.find_by(role_id: member.id)
          remove_member(membership, grouping)
        end
      end
    end
  end

  # Removes the given student membership from the given grouping
  def remove_member(membership, grouping)
    grouping.remove_member(membership.id)
    grouping.reload
  end

  # Format OCR suggestions for JSON response
  def format_ocr_suggestions(ocr_suggestions)
    ocr_suggestions.map do |s|
      {
        id: s[:student].id,
        user_name: s[:student].user.user_name,
        id_number: s[:student].user.id_number,
        display_name: s[:student].user.display_name,
        similarity: (s[:similarity] * 100).round(1)
      }
    end
  end

  # This override is necessary because this controller is acting as a controller
  # for both groups and groupings.
  #
  # TODO: move all grouping methods into their own controller and remove this
  def record
    @record ||= Grouping.find_by(id: request.path_parameters[:id]) if request.path_parameters[:id]
  end
end
