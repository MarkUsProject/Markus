require 'encoding'
require 'auto_complete'
require 'csv_invalid_line_error'

# Manages actions relating to editing and modifying
# groups.
class GroupsController < ApplicationController
  include GroupsHelper
  # Administrator
  before_filter      :authorize_only_for_admin

  auto_complete_for :student, :user_name
  auto_complete_for :assignment, :name

  def note_message
    @assignment = Assignment.find(params[:id])
    if params[:success]
      flash[:notice] = I18n.t('notes.create.success')
    else
      flash[:error] = I18n.t('notes.error')
    end
  end

  # Group administration functions -----------------------------------------
  # Verify that all functions below are included in the authorize filter above

  def new
    assignment = Assignment.find(params[:assignment_id])
    begin
      assignment.add_group(params[:new_group_name])
    rescue Exception => e
      flash[:error] = e.message
    ensure
      head :ok
    end
  end

  def remove_group
    # When a success div exists we can return successfully removed groups
    return unless request.delete?
    grouping = Grouping.find(params[:grouping_id])
    @assignment = grouping.assignment
    @errors = []
    @removed_groupings = []
    students_to_remove = grouping.students.to_a
    grouping.student_memberships.each do |member|
      grouping.remove_member(member.id)
    end
    # TODO: return errors through request
    if grouping.has_submission?
        @errors.push(grouping.group.group_name)
    else
      grouping.delete_grouping
      @removed_groupings.push(grouping)
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
      @group.save
    else

      # We link the grouping to the group already existing

      # We verify there is no other grouping linked to this group on the
      # same assignement
      params[:groupexist_id] = groupexist_id
      params[:assignment_id] = @assignment.id

      if Grouping.where(assignment_id: @assignment.id, group_id: groupexist_id)
                 .to_a
         flash[:error] = I18n.t('groups.rename_group.already_in_use')
      else
        @grouping.update_attribute(:group_id, groupexist_id)
      end
    end
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
    @clone_assignments = Assignment.where(allow_web_submits: false)
                                   .where.not(id: @assignment.id)
                                   .order(:id)
    render 'index'
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])
    students_table_info = get_students_table_info
    groupings_table_info = get_groupings_table_info
    render json: [students_table_info, groupings_table_info]
  end

  # Allows the user to upload a csv file listing groups. If group_name is equal
  # to the only member of a group and the assignment is configured with
  # allow_web_subits == false, the student's username will be used as the
  # repository name. If MarkUs is not repository admin, the repository name as
  # specified by the second field will be used instead.
  def csv_upload
    file = params[:group][:grouplist]
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if request.post? && !params[:group].blank?
      # Transaction allows us to potentially roll back if something
      # really bad happens.
      ActiveRecord::Base.transaction do
        file = file.utf8_encode(encoding)
        lines = 0
        begin
          # Loop over each row, which lists the members to be added to the group.
          CSV.parse(file).each_with_index do |row, line_nr|
            begin
              # Potentially raises CSVInvalidLineError
              collision_error = @assignment.add_csv_group(row)
              unless collision_error.nil?
                flash_message(:error, I18n.t('csv.line_nr_csv_file_prefix',
                  { line_number: line_nr + 1 }) + " #{collision_error}")
              end
            rescue CSVInvalidLineError => e
              flash_message(:error, I18n.t('csv.line_nr_csv_file_prefix',
                { line_number: line_nr + 1 }) + " #{e.message}")
            end
            lines = line_nr + 1
          end
          @assignment.reload # Need to reload to get newly created groupings
          number_groupings_added = @assignment.groupings.length
          if number_groupings_added > 0 && flash[:error].is_a?(Array)
            invalid_lines_count = flash[:error].length
            flash[:notice] = I18n.t('csv.groups_added_msg',
                                    number_groups: lines - invalid_lines_count,
                                    number_lines: invalid_lines_count)
          end
        rescue CSV::MalformedCSVError
          flash[:error] = t('csv.upload.malformed_csv')
          raise ActiveRecord::Rollback
        rescue ArgumentError
          flash[:error] = I18n.t('csv.upload.non_text_file_with_csv_extension')
          raise ActiveRecord::Rollback
        rescue Exception
          # We should only get here if something *really* bad/unexpected
          # happened.
          flash_message(:error, I18n.t('csv.groups_unrecoverable_error'))
          raise ActiveRecord::Rollback
        end
      end
      # Need to reestablish repository permissions.
      # This is not handled by the roll back.

      # The generation of the permissions file has been moved out of the transaction
      # for perfomance reasons. Because the groups are being created as part of
      # this transaction, the race condition of the repos being created before the 
      # permissions are set should not be a problem.
      Repository::SubversionRepository.__generate_authz_file
    end
    redirect_to action: 'index', id: params[:id]
  end

  def create_groups_when_students_work_alone
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.group_max == 1
      @current_job = CreateIndividualGroupsForAllStudentsJob.perform_later @assignment
    end
    respond_to do |format|
      format.js {}
    end
  end

  def download_grouplist
    assignment = Assignment.find(params[:assignment_id])

    #get all the groups
    groupings = assignment.groupings #FIXME: optimize with eager loading

    file_out = CSV.generate do |csv|
       groupings.each do |grouping|
         group_array = [grouping.group.group_name, grouping.group.repo_name]
         # csv format is group_name, repo_name, user1_name, user2_name, ... etc
         grouping.student_memberships.includes(:user).each do |member|
            group_array.push(member.user.user_name)
         end
         csv << group_array
       end
     end

    send_data(file_out, type: 'text/csv', disposition: 'inline')
  end

  def use_another_assignment_groups
    target_assignment = Assignment.find(params[:assignment_id])
    source_assignment = Assignment.find(params[:clone_assignment_id])

    if source_assignment.nil?
      flash[:warning] = t('groups.csv.could_not_find_source')
    elsif target_assignment.nil?
      flash[:warning] = t('groups.csv.could_not_find_target')
    else
      # Clone the groupings
      target_assignment.clone_groupings_from(source_assignment.id)
    end

    redirect_to :back
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
      render text: e.message, status: 400
    end
  end

  private
  # These methods are called through global actions.
  
  # Check that there is at least one grouping selected
  def check_for_groupings(groupings)
    if groupings.blank?
      raise I18n.t('assignment.group.select_a_group')
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
      students_to_remove = []
      groupings.each do |grouping|
        students_to_remove = students_to_remove.concat(grouping.students.to_a)
        grouping.student_memberships.each do |mem|
          grouping.remove_member(mem.id)
        end
        grouping.delete_grouping
      end
    end
  end

  # Adds students to grouping. `groupings` should be an array with
  # only one element, which is the grouping that is supposed to be
  # added to.
  def add_members(students, groupings, assignment)
    if groupings.size != 1
      raise I18n.t('assignment.group.select_only_one_group')
    end
    if students.blank?
      raise I18n.t('assignment.group.select_a_student')
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
    members_to_remove = Student.where(id: member_ids_to_remove)
    members_to_remove.each do |member|
      grouping = member.accepted_grouping_for(assignment.id)
      membership = grouping.student_memberships.find_by_user_id(member.id)
      remove_member(membership, grouping, assignment)
    end
  end

  # Removes the given student membership from the given grouping
  def remove_member(membership, grouping, assignment)
    grouping.remove_member(membership.id)
    grouping.reload
  end
end
