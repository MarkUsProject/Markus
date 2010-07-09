require 'fastercsv'
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
      flash[:upload_notice] = I18n.t('notes.create.success')
    else
      flash[:error] = I18n.t('notes.error')
    end
  end
 
  # Group administration functions -----------------------------------------
  # Verify that all functions below are included in the authorize filter above
    
  def add_member    
    return unless (request.post? && params[:student_user_name])
    # add member to the group with status depending if group is empty or not
    grouping = Grouping.find(params[:grouping_id])
    @assignment = Assignment.find(params[:id], 
                                  :include => [{
                                     :groupings => [{
                                        :student_memberships => :user, 
                                        :ta_memberships => :user}, 
                                      :group]}])
    set_membership_status = grouping.student_memberships.empty? ?
          StudentMembership::STATUSES[:inviter] :
          StudentMembership::STATUSES[:accepted]
    @messages = []
    @bad_user_names = []
    @error = false
    
    students = params[:student_user_name].split(',')

    students.each do |user_name|
      user_name = user_name.strip
      @invited = Student.find_by_user_name(user_name)
      begin
        if @invited.nil?
          raise I18n.t('add_student.fail.dne', :user_name => user_name)
        end
        if @invited.hidden
          raise I18n.t('add_student.fail.hidden', :user_name => user_name)
        end
        if @invited.has_accepted_grouping_for?(@assignment.id)
          raise I18n.t('add_student.fail.already_grouped', :user_name => user_name)
        end
        membership_count = grouping.student_memberships.length
        grouping.invite(user_name, set_membership_status, true)
        grouping.reload

        # report success only if # of memberships increased
        if membership_count < grouping.student_memberships.length
          @messages.push(I18n.t('add_student.success', :user_name => user_name))
        else # something clearly went wrong
          raise I18n.t('add_student.fail.general', :user_name => user_name)
        end
        
        # only the first student should be the "inviter" (and 
        # only update this if it succeeded)
        set_membership_status = StudentMembership::STATUSES[:accepted]
      rescue Exception => e
        @error = true
        @messages.push(e.message)
        @bad_user_names.push(user_name)
      end
    end

    grouping.reload
    @grouping = construct_table_row(grouping, @assignment)
    @group_name = grouping.group.group_name
  end
  
  def add_member_dialog
    @assignment = Assignment.find(params[:id])
    @grouping_id = params[:grouping_id]
    render :partial => "groups/modal_dialogs/add_member_dialog.rjs"
  end
 
  def remove_member
    return unless request.delete?
    
    @mbr_id = params[:mbr_id]
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    member = @grouping.student_memberships.find(@mbr_id)  # use group as scope
    @grouping.remove_member(member)
    @grouping.reload
    if !@grouping.inviter.nil?
      @inviter = @grouping.accepted_student_memberships.find_by_user_id(
                         @grouping.inviter.id)
    else
      # There are no group members left, so create an empty table row
      # of FilterTable
      @grouping_table_row = construct_table_row(@grouping, @assignment)
    end
  end
  
  def add_group
    @assignment = Assignment.find(params[:id])
    begin
      new_grouping_data = @assignment.add_group(params[:new_group_name])
    rescue Exception => e
      @error = e.message
      render :action => 'error_single'
      return 
    end
    @new_grouping = construct_table_row(new_grouping_data, @assignment)
  end
  
  def remove_group
    return unless request.delete?
    grouping = Grouping.find(params[:grouping_id])
    @assignment = grouping.assignment
    @errors = []
    @removed_groupings = []
    if grouping.has_submission?
        @errors.push(grouping.group.group_name)
        render :action => "delete_groupings"
    else
      grouping.delete_grouping
      @removed_groupings.push(grouping)
      render :action => "delete_groupings"
    end
  end
  
  def rename_group_dialog
    @assignment = Assignment.find(params[:id])
    @grouping_id = params[:grouping_id]
    render :partial => "groups/modal_dialogs/rename_group_dialog.rjs"
  end

  def rename_group
     @assignment = Assignment.find(params[:id])
     @grouping = Grouping.find(params[:grouping_id]) 
     @group = @grouping.group
    
     # Checking if a group with this name already exists

    if (@groups = Group.find(:first, :conditions => {:group_name =>
     [params[:new_groupname]]}))
         existing = true
         groupexist_id = @groups.id
    end
    
    if !existing
        #We update the group_name
        @group.group_name = params[:new_groupname]
        @group.save
        flash[:edit_notice] = I18n.t('groups.rename_group.success')
     else

        # We link the grouping to the group already existing

        # We verify there is no other grouping linked to this group on the
        # same assignement
        params[:groupexist_id] = groupexist_id
        params[:assignment_id] = @assignment.id

        if Grouping.find(:all, 
                         :conditions => [
                      "assignment_id = :assignment_id and group_id =
                      :groupexist_id", 
                      {:groupexist_id => groupexist_id, 
                       :assignment_id => @assignment.id}])
           flash[:fail_notice] = I18n.t('groups.rename_group.already_in_use')
        else
          @grouping.update_attribute(:group_id, groupexist_id)
          flash[:edit_notice] = I18n.t('groups.rename_group.success')
        end
     end
  end

  def valid_grouping
     @assignment = Assignment.find(params[:id])
     grouping = Grouping.find(params[:grouping_id])
     grouping.validate_grouping
  end
  
  def populate
    @assignment = Assignment.find(params[:id], 
                                 :include => [{
                                   :groupings => [{
                                      :student_memberships => :user, 
                                      :ta_memberships => :user}, 
                                   :group]}])   
    @groupings = @assignment.groupings
    @table_rows = {}
    @groupings.each do |grouping|
      # construct_table_row is in the groups_helper.rb
      @table_rows[grouping.id] = construct_table_row(grouping, @assignment) 
    end
    
  end

  def manage
    @all_assignments = Assignment.all(:order => :id)
    @assignment = Assignment.find(params[:id], 
                                  :include => [{
                                     :groupings => [{
                                        :student_memberships => :user, 
                                        :ta_memberships => :user}, 
                                     :group]}])   
    @groupings = @assignment.groupings
    # Returns a hash where s.id is the key, and student record is the value
    @ungrouped_students = @assignment.ungrouped_students
    @tas = Ta.all
  end
  
  # Assign TAs to Groupings via a csv file
  def csv_upload_grader_mapping
    if !request.post? || params[:grader_mapping].nil?
      flash[:error] = I18n.t("csv.group_to_grader")
      redirect_to :action => 'manage', :id => params[:id]
      return
    end
    
    invalid_lines = Grouping.assign_tas_by_csv(params[:grader_mapping].read, 
                                               params[:id])
    if invalid_lines.size > 0
      flash[:invalid_lines] = invalid_lines
    end
    redirect_to :action => 'manage', :id => params[:id]
  end
  
  # Allows the user to upload a csv file listing groups. If group_name is equal
  # to the only member of a group and the assignment is configured with
  # allow_web_subits == false, the student's username will be used as the
  # repository name. If MarkUs is not repository admin, the repository name as
  # specified by the second field will be used instead.
  def csv_upload
    flash[:error] = nil # reset from previous errors
    flash[:invalid_lines] = nil
    @assignment = Assignment.find(params[:id])
    if request.post? && !params[:group].blank?
      # Transaction allows us to potentially roll back if something
      # really bad happens.
      ActiveRecord::Base.transaction do
        # Old groupings get wiped out
        if !@assignment.groupings.nil? && @assignment.groupings.length > 0
          @assignment.groupings.destroy_all
        end
        flash[:invalid_lines] = [] # Store errors of lines in CSV file
        begin
          # Loop over each row, which lists the members to be added to the group.
          FasterCSV.parse(params[:group][:grouplist]).each_with_index do |row, line_nr|
            begin
              # Potentially raises CSVInvalidLineError
              collision_error = @assignment.add_csv_group(row)
              if !collision_error.nil?
                flash[:invalid_lines] << I18n.t("csv.line_nr_csv_file_prefix",
                                          { :line_number => line_nr + 1 }) 
                                          + " #{collision_error}"
              end
            rescue CSVInvalidLineError => e
              flash[:invalid_lines] << I18n.t("csv.line_nr_csv_file_prefix",
                                          { :line_number => line_nr + 1 }) 
                                          + " #{e.message}"
            end
          end
          @assignment.reload # Need to reload to get newly created groupings
          number_groupings_added = @assignment.groupings.length
          invalid_lines_count = flash[:invalid_lines].length
          if invalid_lines_count == 0
            flash[:invalid_lines] = nil 
          end
          if number_groupings_added > 0
            flash[:upload_notice] = I18n.t("csv.groups_added_msg",
                  { :number_groups => number_groupings_added, 
                    :number_lines => invalid_lines_count })
          end
        rescue Exception => e
          # We should only get here if something *really* bad/unexpected
          # happened.
          flash[:error] = I18n.t("csv.groups_unrecoverable_error")
          raise ActiveRecord::Rollback
        end
      end
      # Need to reestablish repository permissions.
      # This is not handled by the roll back.
      @assignment.update_repository_permissions_forall_groupings
    end
    redirect_to :action => "manage", :id => params[:id]
  end
  
  def download_grouplist
    assignment = Assignment.find(params[:id])

    #get all the groups
    groupings = assignment.groupings #FIXME: optimize with eager loading

    file_out = FasterCSV.generate do |csv|
       groupings.each do |grouping|
         group_array = [grouping.group.group_name, grouping.group.repo_name]
         # csv format is group_name, repo_name, user1_name, user2_name, ... etc
         grouping.student_memberships.all(:include => :user).each do |member|
            group_array.push(member.user.user_name);
         end
         csv << group_array
       end
     end

    send_data(file_out, :type => "text/csv", :disposition => "inline")
  end

  def use_another_assignment_groups
    @target_assignment = Assignment.find(params[:id])
    source_assignment = Assignment.find(params[:clone_groups_assignment_id])
      
    if source_assignment.nil?
      flash[:fail_notice] = I18n.t("groups.csv.could_not_find_source")
    end
    if @target_assignment.nil?
      flash[:fail_notice] = I18n.t("groups.csv.could_not_find_target")
    end
            
    # Clone the groupings
    @target_assignment.clone_groupings_from(source_assignment.id)

    flash[:edit_notice] = I18n.t("groups.csv.groups_created")
  end

  # This method is massive, and does way too much.  Whatever happened
  # to single-responsibility?
  def global_actions 
    @assignment = Assignment.find(params[:id], 
                                  :include => [{
                                     :groupings => [{
                                        :student_memberships => :user, 
                                        :ta_memberships => :user}, 
                                     :group]}])   
    @tas = Ta.all

    if params[:submit_type] == 'random_assign'
      begin 
        if params[:graders].nil?
          raise t('groups.no_graders_selected')
        end
        if params[:groupings].nil?
          raise t('groups.no_groups_selected')
        end
        randomly_assign_graders(params[:graders], params[:groupings])
        @groupings_data = construct_table_rows(Grouping.find(params[:groupings]), 
                                               @assignment)
        render :action => "modify_groupings"
        return
      rescue Exception => e
        @error = e.message
        render :action => 'error_single'
        return
      end
    end
    
    grouping_ids = params[:groupings]
    if params[:groupings].nil? or params[:groupings].size ==  0
      @error = I18n.t("assignment.group.select_one_group")
      render :action => 'error_single'
      return
    end
    @grouping_data = {}
    @groupings = []
    
    case params[:global_actions]
      when "delete"
        @removed_groupings = []
        @errors = []
        groupings = Grouping.find(grouping_ids)
        groupings.each do |grouping|
          if grouping.has_submission?
            @errors.push(grouping.group.group_name)
	        else
            grouping.delete_grouping
            @removed_groupings.push(grouping)
	        end
        end
        render :action => "delete_groupings"
        return
      
      when "invalid"
        groupings = Grouping.find(grouping_ids)
        groupings.each do |grouping|
           grouping.invalidate_grouping
        end
        @groupings_data = construct_table_rows(groupings, @assignment)
        render :action => "modify_groupings"
        return      
      
      when "valid"
        groupings = Grouping.find(grouping_ids)
        groupings.each do |grouping|
           grouping.validate_grouping
        end
        @groupings_data = construct_table_rows(groupings, @assignment)
        render :action => "modify_groupings"
        return
        
      when "assign"
        @groupings_data = assign_tas_to_groupings(grouping_ids, params[:graders])
        render :action => "modify_groupings"
        return
        
      when "unassign"
        @groupings_data = unassign_tas_to_groupings(grouping_ids, params[:graders])
        render :action => "modify_groupings"
        return
    end
  end


end
