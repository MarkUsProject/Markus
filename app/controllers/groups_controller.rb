require 'fastercsv'
require 'auto_complete'


# Manages actions relating to editing and modifying 
# groups.
class GroupsController < ApplicationController
  
  # Administrator
  # -
  
  before_filter      :authorize_only_for_admin, :except => [:creategroup,
  :student_interface, :invite_member, :join, :decline_invitation,
  :delete_rejected, :delete_group]
   
   auto_complete_for :student, :user_name
   auto_complete_for :assignment, :name
  # TODO filter (except index) to make sure assignment is a group assignment
  
  def index
    @assignments = Assignment.all(:order => 'id', 
      :conditions => ["group_max > 1"]) # only group assignments
  end

  def student_interface
     @assignment = Assignment.find(params[:id])
     @student = Student.find(session[:uid])
     @grouping = @student.accepted_grouping_for(@assignment.id)
     @pending_groupings = @student.pending_groupings_for(@assignment.id)
     
     if !@grouping.nil?
       @studentmemberships = @grouping.student_memberships
       @group = @grouping.group
       @inviter = StudentMembership.find(:first, :conditions =>
       {:grouping_id => @grouping.id, :membership_status =>
       StudentMembership::STATUSES[:inviter] })
     end

     # To list the students not in a group yet
     # We make a list of all students
     @students = Student.all
     @students_list = []
     @students.each do |s|
       if !s.has_accepted_grouping_for?(@assignment.id)
         @students_list.push(s)
       end
     end
     @students = @students_list
  end
  
  # Group management functions ---------------------------------------------
  
  def creategroup
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    @student = Student.find(session[:uid])
    # Create new group for this assignment
    @grouping = Grouping.new
    @grouping.assignment = @assignment
        # The student chose to work alone for this assignment.
    # He is then using his personnal repository. 
    # The grouping he belongs to is then linked to a group which has the
    # student's username as groupname
    if params[:workalone]
      # We therefore start by checking if the student's already have an
      # existing group
      if Group.find(:first, :conditions => {:group_name => @student.user_name})
        group = Group.find(:first, :conditions => {:group_name => @student.user_name})
      else
        group = Group.new
        group.save(false)
        group.group_name = @student.user_name
        group.save
      end
    else
      group = Group.new
      group.save(false)
      group.group_name = "group_" + group.id.to_s
      group.save
    end
    @grouping.group = group
    @grouping.save 
    # Set this user as inviter

    # If the student is invited in an other group, we need to erase the
    # membership linked to the other group
    @student.pending_groupings_for(@assignment.id).each do |grouping|
      membership = grouping.student_memberships.find_by_user_id(@student.id)
      membership.destroy
    end

    # Creates a new membership
    @member = StudentMembership.new(:grouping_id => @grouping.id,
    :user_id => @student.id, :membership_status => StudentMembership::STATUSES[:inviter])
    @member.save
    
    # check if user is forming group on its own
    unless params[:group] && params[:group][:single] == '1'
      if params[:members]
        users = params[:members].values.map { |m| m['user_name'].strip  }
        @grouping.invite(users)  # invite members to this group
      end
    end
    @grouping.save
    # display ajax response
    render :update do |page|
        page.redirect_to :controller => 'groups', :action => 'student_interface', :id => @assignment.id
    end
    
  end
  
  #

  # Invite members to group
  def invite_member
    return unless (request.post?)
    @assignment = Assignment.find(params[:id])
    @student = Student.find(session[:uid]) # student who invites
    @grouping = @student.accepted_grouping_for(@assignment.id) # his group

    @invited = Student.find(params[:invite_member])
    # We first check he isn't already invited for this grouping
    groupings = @invited.pending_groupings_for(@assignment.id)

    already_pending_member = false
    groupings.each do |g|
       if g.id == @grouping.id
          already_pending_member = true
       end
    end
    if !already_pending_member
       @invited.invite(@grouping.id)
       flash[:edit_notice] = "Student invited."
    else
       flash[:fail_notice] = "This student is already a pending member
       of this group!"
    end

    render :update do |page|
      page.redirect_to :action => 'student_interface', :id =>
      @assignment.id
    end
  end

  def join
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    @user.join(@grouping.id)
    
    render :update do |page|
      page.redirect_to :action => 'student_interface', :id => @assignment.id
   end
  end
  
  # Remove rejected member
  def decline_invitation
    @assignment = Assignment.find(params[:id])
    @grouping = Grouping.find(params[:grouping_id])
    @user = Student.find(session[:uid])
    membership = StudentMembership.find(:first, :conditions => {:user_id => @user.id, :grouping_id => @grouping.id})
    return unless request.post?
    membership.membership_status = StudentMembership::STATUSES[:rejected]
    membership.save
    render :update do |page|
      page.redirect_to :action => 'student_interface', :id => @assignment.id
    end 
  end

  def delete_rejected
     assignment = Assignment.find(params[:id])
     membership = StudentMembership.find(params[:membership])
     membership.delete
     membership.save
     
     render :update do |page|
        page.redirect_to :action => 'student_interface', :id =>
        assignment.id
     end
  end
  
   def delete_group
    @assignment = Assignment.find(params[:id])
    return unless request.delete?
    # TODO remove groups for all assignment or just for the specific assignment?
    # TODO remove submissions in file system?
    @grouping = Grouping.find(params[:grouping_id])
    if @grouping.has_submission?
        flash[:fail_notice] = "This groups already has some submission.
        You cannot delete it."
    else
        @grouping.student_memberships.all(:include => :user).each do |member|
          member.destroy
        end
        @grouping.destroy
    end

    render :update do |page|
       page.redirect_to :controller => 'assignments', :action => 'student_interface', :id => @assignment.id
    end
  
  end

 
  # Group administration functions -----------------------------------------
  # Verify that all functions below are included in the authorize filter above
    
  def add_member
    return unless (request.post? && params[:student][:user_name])
    # add member to the group with status depending if group is empty or not
    grouping = Grouping.find(params[:grouping_id])
    @assignment = Assignment.find(params[:id])
    membership_status = grouping.student_memberships.empty? ?
    StudentMembership::STATUSES[:inviter] :
    StudentMembership::STATUSES[:accepted]     
    member = grouping.invite(params[:student][:user_name], membership_status) 
    render :update do |page|
      if grouping.save
        # add member to the group list
        page.insert_html :bottom, "grouping_#{grouping.id}_list", 
          :partial => 'groups/manage/member', :locals => {:grouping => grouping, :member => member}
        # remove from 'no group' list if in there
        page.remove "user_#{params[:student][:user_name]}"
        page.call(:clearText, grouping.id.to_s)  # clear text
        page.replace_html("error_#{grouping.id}", "")  # clear errors
      else
        page.replace_html "error_#{grouping.id}",
          :partial => 'groups/error_single', :locals => { :objekt => grouping }
      end
    end
  end
 
  def remove_member
    return unless request.delete?
    
    grouping = Grouping.find(params[:grouping_id])
    member = grouping.student_memberships.find(params[:mbr_id])  # use group as scope
    student = member.user  # need to find user name to add to student list
    
    inviter = nil  # new inviter if member being removed is an inviter
    # randomly assign new inviter and rename submission file
    if member.inviter?  && grouping.student_memberships.count > 1
      @assignment = Assignment.find(params[:id])
      # subm = @assignment.submission_by(student) #FIXME: make sure if submitter is removed, transfer 
      inviter = group.student_memberships.first(:order => "created_at", 
        :conditions => ["membership_status = 'accepted'"])
      # subm.owner = inviter.user  # assign new_inviter as submission owner
      inviter.membership_status = StudentMembership::STATUSES[:inviter]
      inviter.save
    end
    
    member.destroy
    render :update do |page|
      page.visual_effect(:fade, "mbr_#{params[:mbr_id]}", :duration => 0.5)
      page.delay(0.5) { page.remove "mbr_#{params[:mbr_id]}" }
      # add members back to student list
      page.insert_html :bottom, "student_list",  
        "<li id='user_#{student.user_name}'>#{student.user_name}</li>"
      if inviter
        # replace the status of the new inviter to 'inviter'
        page.remove "mbr_#{inviter.id}"
        page.insert_html :top, "group_#{group.id}_list", 
          :partial => 'groups/manage/member', :locals => {:group => group, :member => inviter}
      end
    end
  end
  
  def add_group
    @assignment = Assignment.find(params[:id])
    if @assignment.group_name_autogenerated
      # Create new group for this assignment
      group = Group.new
      group.save(false) # skip validation requiring groups to have at least 1 member 
      # We need to save before we can get an ID for this group.
      group.group_name = "group_" + group.id.to_s    
      group.save # Second save, to preserve the name
    else 
      #test if a group with this name already exists
      if Group.find(:first, :conditions => {:group_name => [params[:new_group_name]]})
        group = Group.find(:first, :conditions => {:group_name => [params[:new_group_name]]})
        params[:assignment_id] = @assignment.id
        params[:group_id] = group.id  
        #test if a grouping is already linked to this group
        if Grouping.find(:first, :conditions => ["assignment_id =:assignment_id and group_id = :group_id", {:group_id => group.id, :assignment_id => @assignment.id}])
           flash[:fail_notice] = "This name is already uses for this
           assignement"
           render :update do |page|
              page.redirect_to :action => 'manage', :id =>  @assignment.id
           end
           return
      end
      else
        # Create new group for this assignment
        group = Group.new
        group.group_name = params[:new_group_name]    
        group.save # Second save, to preserve the name
      end
    end 
    grouping = Grouping.new
    grouping.group = group
    grouping.assignment = @assignment
    grouping.save
		
    render :update do |page|
      page.redirect_to :action => 'manage', :id => @assignment.id
      page.call(:focusText, grouping.id.to_s)
    end
  end
  
  def remove_group
    @assignment = Assignment.find(params[:id])
    return unless request.delete?
    # TODO remove groups for all assignment or just for the specific assignment?
    # TODO remove submissions in file system?
    @grouping = Grouping.find(params[:grouping_id])
    if @grouping.has_submission?
        flash[:fail_notice] = "This groups already has some submission.
        You cannot delete it."
        render :update do |page|
          page.redirect_to :action => 'manage', :id => @assignment.id
        end
    else
      render :update do |page|
        # update list of users not in group
        @grouping.student_memberships.all(:include => :user).each do |member|
          student = member.user
          page.insert_html :bottom, "student_list",  
            "<li id='user_#{student.user_name}'>#{student.user_name}</li>"
          member.destroy
        end
        page.visual_effect(:fade, "grouping_#{params[:grouping_id]}", :duration => 0.5)
        page.delay(0.5) { page.remove "grouping_#{params[:grouping_id]}"  }
      end
      @grouping.destroy
    end
  end

  def rename_group
     @assignment = Assignment.find(params[:id])
     @grouping = Grouping.find(params[:grouping_id]) 
     @group = @grouping.group

     # Checking if a group with this name already exists

    if @groups = Group.find(:first, :conditions => {:group_name =>
     [params[:new_groupname]]})
         existing = true
         groupexist_id = @groups.id
    end
    
    if !existing
        #We update the group_name
        @group.group_name = params[:new_groupname]
        @group.save
        flash[:edit_notice] = "Group name has been updated"
     else

        # We link the grouping to the group already existing

        # We verify there is no other grouping linked to this group on the
        # same assignement
        params[:groupexist_id] = groupexist_id
        params[:assignment_id] = @assignment.id

        if Grouping.find(:all, :conditions => ["assignment_id =
        :assignment_id and group_id = :groupexist_id", {:groupexist_id =>
        groupexist_id, :assignment_id => @assignment.id}])
           flash[:fail_notice] = "This name is already used for this
           assignement"
        else
          @grouping.update_attribute(:group_id, groupexist_id)
          flash[:edit_notice] = "Group name has been changed"
        end
     end
     
     render :update do |page|
       page.redirect_to :action => 'manage', :id => @assignment.id
     end
  end

  def valid_grouping
     @assignment = Assignment.find(params[:id])
     grouping = Grouping.find(params[:grouping_id])
     grouping.admin_approved = true
     grouping.save

     render :update do |page|
       page.redirect_to :action => 'manage', :id => @assignment.id
     end
  end


  def manage
    @all_assignments = Assignment.all(:order => :id)
    @assignment = Assignment.find(params[:id])   
    @groupings = @assignment.groupings 
    # Returns a hash where s.id is the key, and student record is the value
    @students = Student.all.index_by { |s| s.id }   
  end
  
  # Allows the user to upload a csv file listing groups.
  def csv_upload
    if request.post? && !params[:group].blank?
      @assignment = Assignment.find(params[:id])
   	  num_update = 0
      flash[:invalid_lines] = []  # store lines that were not processed
      
      # Loop over each row, which lists the members to be added to the group.
      FasterCSV.parse(params[:group][:grouplist]) do |row|
		if add_csv_group(row, @assignment) == nil
		    flash[:invalid_lines] << row.join(",")
		else
       		num_update += 1
     	end
	   end
	   flash[:upload_notice] = "#{num_update} group(s) added."
     end
     redirect_to :action => 'manage', :id => @assignment.id
  end
  
  # Helper method to add the listed members.
  def add_csv_group (group, assignment)

  	return nil if group.length <= 0
	  @grouping = Grouping.new
      @grouping.assignment_id = assignment.id
      # If a group with this name already exist, link the grouping to
      # this group. else create the group
      if Group.find(:first, :conditions => {:group_name => group[0]})
         @group = Group.find(:first, :conditions => {:group_name => group[0]})
	  else
         @group = Group.new
         @group.group_name = group[0]	
         @group.save
      end

      @grouping.group_id = @group.id
      @grouping.save
      # Add first member to group.
      student = Student.find(:first, :conditions => {:user_name => group[1]})
      member = @grouping.add_member(student)
      member.membership_status = StudentMembership::STATUSES[:inviter]
      member.save
      for i in 2..group.length do
        student = Student.find(:first, :conditions => {:user_name =>group[i]})
        @grouping.add_member(student)
      end
  end
  
  def download_grouplist
    assignment = Assignment.find(params[:id])

    #get all the groups
    groupings = assignment.groupings #FIXME: optimize with eager loading

    file_out = FasterCSV.generate do |csv|
       groupings.each do |grouping|
         group_array = [grouping.group.group_name]
         # csv format is group_name, user1_name, user2_name, ... etc
         grouping.memberships.all(:include => :user).each do |member|
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
      flash[:fail_notice] = "Could not find source assignment for cloning groups"
    end
    if @target_assignment.nil?
      flash[:fail_notice] = "Could not find target assignment for cloning groups"
    end
      
    # First, destroy all groupings for the target assignment
    @target_assignment.groupings.each do |grouping|
      grouping.destroy
    end
      
    # Next, we need to set the target assignments grouping settings to match
    # the source assignment

    @target_assignment.group_min = source_assignment.group_min
    @target_assignment.group_max = source_assignment.group_max
    @target_assignment.student_form_groups = source_assignment.student_form_groups
    @target_assignment.group_name_autogenerated = source_assignment.group_name_autogenerated
    @target_assignment.group_name_displayed = source_assignment.group_name_displayed
    
    source_groupings = source_assignment.groupings

    source_groupings.each do |old_grouping|
      #create the groupings
      new_grouping = Grouping.new
      new_grouping.assignment_id = @target_assignment.id
      new_grouping.group_id = old_grouping.group_id
      new_grouping.save
      #create the memberships - both TA and Student memberships
      old_memberships = old_grouping.memberships
      old_memberships.each do |old_membership|
        new_membership = Membership.new
        new_membership.user_id = old_membership.user_id
        new_membership.membership_status = old_membership.membership_status
        new_membership.grouping = new_grouping
        new_membership.type = old_membership.type
        new_membership.save
      end
    end

    flash[:edit_notice] = "Groups created"

    render :update do |page|
        page.redirect_to :action => 'manage', :id => @target_assignment.id
    end
  
  end

  # creates all the groups when the instructor wants the student to work
  # alone
  def create_groups_when_students_work_alone
    @assignment = Assignment.find(params[:id])
    @students = Student.find(:all)
    for @student in @students
      @student.create_group(@assignment.id)
    end
  end

end
