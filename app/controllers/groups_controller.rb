require 'encoding'
require 'auto_complete'
require 'csv_invalid_line_error'

# Manages actions relating to editing and modifying
# groups.
class GroupsController < ApplicationController
  include GroupsHelper
  # Administrator
  # -
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
    @assignment = Assignment.find(params[:assignment_id])
    begin
      new_grouping_data = @assignment.add_group(params[:new_group_name])
    rescue Exception => e
      @error = e.message
      render :error_single
      return
    end
    @new_grouping = construct_table_row(new_grouping_data, @assignment)
    render :add_group, formats: [:js]
  end

  def remove_group
    return unless request.delete?
    grouping = Grouping.find(params[:grouping_id])
    @assignment = grouping.assignment
    @errors = []
    @removed_groupings = []
    students_to_remove = grouping.students.all
    grouping.student_memberships.all.each do |member|
      grouping.remove_member(member.id)
    end
    @students_data = construct_student_table_rows(students_to_remove, @assignment)
    if grouping.has_submission?
        @errors.push(grouping.group.group_name)
        render :delete_groupings, formats: [:js]
    else
      grouping.delete_grouping
      @removed_groupings.push(grouping)
      render :delete_groupings, formats: [:js]
    end
  end

  def upload_dialog
    @assignment = Assignment.find(params[:id])
    render partial: 'groups/modal_dialogs/upload_dialog', handlers: [:rjs]
  end

  def download_dialog
    @assignment = Assignment.find(params[:id])
    render partial: 'groups/modal_dialogs/download_dialog', handlers: [:rjs]
  end

  def rename_group_dialog
    @assignment = Assignment.find(params[:assignment_id])
    # id is really the grouping_id, this is due to rails routing
    @grouping_id = params[:id]
    render partial: 'groups/modal_dialogs/rename_group_dialog', handlers: [:rjs]
  end

  def rename_group
    @assignment = Assignment.find(params[:assignment_id])
    # group_id is really the grouping_id, this is due to rails routing
    @grouping = Grouping.find(params[:id])
    @group = @grouping.group

    # Checking if a group with this name already exists

    if (@groups = Group.first(conditions: {group_name:
    [params[:new_groupname]]}))
       existing = true
       groupexist_id = @groups.id
    end

    unless existing
      #We update the group_name
      @group.group_name = params[:new_groupname]
      @group.save
    else

      # We link the grouping to the group already existing

      # We verify there is no other grouping linked to this group on the
      # same assignement
      params[:groupexist_id] = groupexist_id
      params[:assignment_id] = @assignment.id

      if Grouping.all(conditions: ["assignment_id =
      :assignment_id and group_id = :groupexist_id", {groupexist_id:
      groupexist_id, assignment_id: @assignment.id}])
         flash[:error] = I18n.t('groups.rename_group.already_in_use')
      else
        @grouping.update_attribute(:group_id, groupexist_id)
      end
    end
    @grouping_data = construct_table_row(@grouping, @assignment)
    render :rename_group, formats: [:js]
  end

  def valid_grouping
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping_id])
    @grouping.validate_grouping
    @grouping_data = construct_table_row(@grouping, @assignment)
    render :valid_grouping, formats: [:js]
  end

  def invalid_grouping
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping_id])
    @grouping.invalidate_grouping
    @grouping_data = construct_table_row(@grouping, @assignment)
    render :invalid_grouping, formats: [:js]
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id],
                                  include: [{
                                      groupings: [
                                          :students,
                                          :non_rejected_student_memberships,
                                          :group]}])
    @groupings = @assignment.groupings
    @table_rows = {}
    @table_rows = construct_table_rows(@groupings, @assignment)
    render :populate, formats: [:js]
  end

  def populate_students
    @assignment = Assignment.find(params[:assignment_id],
                                  include: [:groupings])
    @students = Student.all
    @table_rows = construct_student_table_rows(@students, @assignment)
  end

  def index
    @all_assignments = Assignment.all(order: :id)
    @assignment = Assignment.find(params[:assignment_id])
  end

  # Allows the user to upload a csv file listing groups. If group_name is equal
  # to the only member of a group and the assignment is configured with
  # allow_web_subits == false, the student's username will be used as the
  # repository name. If MarkUs is not repository admin, the repository name as
  # specified by the second field will be used instead.
  def csv_upload
    flash[:error] = nil # reset from previous errors
    file = params[:group][:grouplist]
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if request.post? && !params[:group].blank?
      # Transaction allows us to potentially roll back if something
      # really bad happens.
      ActiveRecord::Base.transaction do
        file = file.utf8_encode(encoding)
        # Old groupings get wiped out
        if !@assignment.groupings.nil? && @assignment.groupings.length > 0
          @assignment.groupings.destroy_all
        end
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
          end
          @assignment.reload # Need to reload to get newly created groupings
          number_groupings_added = @assignment.groupings.length
          if number_groupings_added > 0 && flash[:error].is_a?(Array)
            invalid_lines_count = flash[:error].length
            flash[:notice] = I18n.t('csv.groups_added_msg', { number_groups:
              number_groupings_added, number_lines: invalid_lines_count })
          end
        rescue Exception
          # We should only get here if something *really* bad/unexpected
          # happened.
          flash_message(:error, I18n.t('csv.groups_unrecoverable_error'))
          raise ActiveRecord::Rollback
        end
      end
      # Need to reestablish repository permissions.
      # This is not handled by the roll back.
      @assignment.update_repository_permissions_forall_groupings
    end
    redirect_to action: 'index', id: params[:id]
  end

  def download_grouplist
    assignment = Assignment.find(params[:assignment_id])

    #get all the groups
    groupings = assignment.groupings #FIXME: optimize with eager loading

    file_out = CSV.generate do |csv|
       groupings.each do |grouping|
         group_array = [grouping.group.group_name, grouping.group.repo_name]
         # csv format is group_name, repo_name, user1_name, user2_name, ... etc
         grouping.student_memberships.all(include: :user).each do |member|
            group_array.push(member.user.user_name)
         end
         csv << group_array
       end
     end

    send_data(file_out, type: 'text/csv', disposition: 'inline')
  end

  def use_another_assignment_groups
    @target_assignment = Assignment.find(params[:assignment_id])
    source_assignment = Assignment.find(params[:clone_groups_assignment_id])

    if source_assignment.nil?
      flash[:warning] = I18n.t('groups.csv.could_not_find_source')
    end
    if @target_assignment.nil?
      flash[:warning] = I18n.t('groups.csv.could_not_find_target')
    end

    # Clone the groupings
    @target_assignment.clone_groupings_from(source_assignment.id)
  end

  #These actions act on all currently selected students & groups
  def global_actions
    @assignment = Assignment.find(params[:assignment_id],
                                  include: [{
                                      groupings: [{
                                          student_memberships: :user,
                                          ta_memberships: :user},
                                        :group]}])
    @tas = Ta.all
    grouping_ids = params[:groupings]
    student_ids = params[:students]

    if params[:groupings].nil? or params[:groupings].size ==  0
      # If there is a global action than there should be a group selected
      if params[:global_actions]
        @global_action_warning = t('assignment.group.select_a_group')
        render partial: 'shared/global_action_warning', formats:[:js], handlers: [:erb]
        return
      end
      # Just do nothing
      render nothing: true
      return
    end

    @grouping_data = {}
    @groupings = []
    groupings = Grouping.find(grouping_ids)

    case params[:global_actions]
      when 'delete'
        delete_groupings(groupings)
        return
      when 'invalid'
        invalidate_groupings(groupings)
        return
      when 'valid'
        validate_groupings(groupings)
        return
      when 'assign'
        if grouping_ids.length != 1
          @error = I18n.t('assignment.group.select_only_one_group')
          render :error_single
        elsif student_ids
          add_members(student_ids, grouping_ids[0], @assignment)
          return
        else
          @global_action_warning = t('assignment.group.select_a_student')
          render partial: 'shared/global_action_warning', formats:[:js], handlers: [:erb]
          return
        end
      when 'unassign'
        remove_members(groupings, params)
        return
    end
  end

  private
  #These methods are called through global actions

  # Given a list of grouping, sets their group status to invalid if possible
  def invalidate_groupings(groupings)
    groupings.each do |grouping|
     grouping.invalidate_grouping
    end
    @groupings_data = construct_table_rows(groupings, @assignment)
    render :modify_groupings, formats: [:js]
  end

  # Given a list of grouping, sets their group status to valid if possible
  def validate_groupings(groupings)
    groupings.each do |grouping|
      grouping.validate_grouping
    end
    @groupings_data = construct_table_rows(groupings, @assignment)
    render :modify_groupings, formats: [:js]
  end

  # Deletes the given list of groupings if possible. Removes each member first.
  def delete_groupings(groupings)
      @removed_groupings = []
      @errors = []
      students_to_remove = []
      groupings.each do |grouping|
        students_to_remove = students_to_remove.concat(grouping.students.all)
        grouping.student_memberships.all.each do |mem|
          grouping.remove_member(mem.id)
        end
        if grouping.has_submission?
          @errors.push(grouping.group.group_name)
        else
          grouping.delete_grouping
          @removed_groupings.push(grouping)
        end
      end
      @students_data = construct_student_table_rows(students_to_remove, @assignment)
      render :delete_groupings, formats: [:js]
  end

  # Adds the students given in student_ids to the grouping given in grouping_id
  def add_members(student_ids, grouping_id, assignment)
    students = Student.find(student_ids)
    grouping = Grouping.find(grouping_id)
    students.each do |student|
      add_member(student, grouping, assignment)
    end
    @groupings_data = construct_table_rows([grouping], @assignment)
    @students_data = construct_student_table_rows(students, @assignment)

    # Generate warning if the number of people assigned to a group exceeds
    # the maximum size of a group
    students_in_group = grouping.student_membership_number
    group_name = grouping.group.group_name
    if assignment.student_form_groups
      if students_in_group > assignment.group_max
        @warning_group_size = I18n.t('assignment.group.assign_over_limit',
          group: group_name)

      end
    end
    render :add_members, formats: [:js]
  end

  # Adds the student given in student_id to the grouping given in grouping
  def add_member  (student, grouping, assignment)
    set_membership_status = grouping.student_memberships.empty? ?
          StudentMembership::STATUSES[:inviter] :
          StudentMembership::STATUSES[:accepted]
    @messages = []
    @bad_user_names = []
    @error = false

    begin
      if student.hidden
        raise I18n.t('add_student.fail.hidden', user_name: student.user_name)
      end
      if student.has_accepted_grouping_for?(@assignment.id)
        raise I18n.t('add_student.fail.already_grouped',
          user_name: student.user_name)
      end
      membership_count = grouping.student_memberships.length
      grouping.invite(student.user_name, set_membership_status, true)
      grouping.reload

      # report success only if # of memberships increased
      if membership_count < grouping.student_memberships.length
        @messages.push(I18n.t('add_student.success',
            user_name: student.user_name))
      else # something clearly went wrong
        raise I18n.t('add_student.fail.general',
          user_name: student.user_name)
      end

      # only the first student should be the "inviter"
      # (and only update this if it succeeded)
      set_membership_status = StudentMembership::STATUSES[:accepted]

      # generate a warning if a member is added to a group and they
      # have less grace days credits than already used by that group
      if student.remaining_grace_credits < grouping.grace_period_deduction_single
        @warning_grace_day = I18n.t('assignment.group.grace_day_over_limit',
          group: grouping.group.group_name)
      end
    rescue Exception => e
      @error = true
      @messages.push(e.message)
    end

    grouping.reload
    @grouping = construct_table_row(grouping, assignment)
    @group_name = grouping.group.group_name
  end

  # Removes the students contained in params from the groupings given
  # in groupings.
  # This is meant to be called with the params from global_actions, and for
  # each student to delete it will have a parameter
  # of the form "groupid_studentid"
  def remove_members(groupings, params)
    all_members = []
    groupings.each do |grouping|
      members = grouping.students.delete_if do |student|
                  !params["#{grouping.id}_#{student.user_name}"]
                end
      memberships = members.map do |member|
        grouping.student_memberships.find_by_user_id(member.id)
      end
      memberships.each do |membership|
        remove_member(membership, grouping, @assignment)
      end
      all_members = all_members.concat(members)
    end
    @students_data = construct_student_table_rows(all_members, @assignment)
    @groupings_data = construct_table_rows(groupings, @assignment)
    render :remove_members, formats: [:js]
  end

  #Removes the given student membership from the given grouping
  def remove_member(membership, grouping, assignment)
    @grouping = grouping
    grouping.remove_member(membership.id)
    grouping.reload
    unless grouping.inviter.nil?
      @inviter = grouping.accepted_student_memberships.find_by_user_id(grouping.inviter.id)
    end
  end
end
