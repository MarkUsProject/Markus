class GroupsController < ApplicationController
  
  before_filter      :authorize, 
    :only => [:manage, :add_member, :remove_member, :add_group, :remove_group]
  # TODO filter (except index) to make sure assignment is a group assignment
  
  def index
    @assignments = Assignment.all(:order => 'id', 
      :conditions => ["group_max > 1"]) # only group assignments
  end
  
  # Group management functions ---------------------------------------------
  
  def creategroup
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    
    # Create new group for this assignment
    @group = Group.new
    @group.assignments << @assignment
    
    # Set this user as inviter
    @group.add_member(current_user, 'inviter')
    # check if user is forming group on its own
    unless params[:group] && params[:group][:single] == '1'
      if params[:members]
        users = params[:members].values.map { |m| m['user_name'].strip  }
        @group.invite(users)  # invite members to this group
      end
    end
    
    # display ajax response
    render :update do |page|
      if @group.valid_with_base? && @group.save
        page.redirect_to :controller => 'submissions', 
          :action => 'submit', :id => @assignment.id
      else
        page.replace_html 'creategroup_error',
          :partial => 'groups/error_single', :locals => { :objekt => @group }
      end
    end
    
  end
  
  # Add additional members to group
  def add_members
    return unless (request.post? && params[:members])
    @assignment = Assignment.find(params[:id])
    @group = current_user.group_for(@assignment.id) # assert not nil
    
    # add additional members to the group if requested
    users = params[:members].values.map { |m| m['user_name'].strip  }
    @group.invite(users)
    
    render :update do |page|
      page.replace "module_groups", :partial => 'groups/status'
      unless @group.valid_with_base?
        page.replace_html 'addmembers_error',
          :partial => 'groups/error_single', :locals => { :objekt => @group }
      end
    end
  end
  
  # Changes the user's member status for an assignment. 
  # If user rejects invite, user is removed from the group
  def join
    @assignment = Assignment.find(params[:id])
    group = current_user.group_for(@assignment.id)
    @inviter = group.inviter
    return unless request.post?
    
    if group && group.pending?(current_user)
      if params[:accept]
        group.accept(current_user)
      elsif params[:reject]
        group.reject(current_user)
      end
    end
    
    redirect_to :controller => 'submissions', 
      :action => 'submit', :id => @assignment.id
  end
  
  # Remove rejected member
  def remove_rejected
    return unless request.delete?
    @group = current_user.group_for(params[:id]) # assert not nil
    
    return unless @group.inviter == current_user
    @group.remove_rejected(params[:member_id])
    render :update do |page|
      page.visual_effect(:fade, "mbr_#{params[:member_id]}")
    end
  end
  
  
  # Group administration functions -----------------------------------------
  # Verify that all functions below are included in the authorize filter above
  
  def add_member
    return unless (request.post? && params[:member_name])
    
    # add member to the group with status depending if group is empty or not
    group = Group.find(params[:group_id])
    status = group.memberships.empty? ? 'inviter' : 'accepted'
    member = group.invite(params[:member_name][group.id.to_s], status)
    
    render :update do |page|
      if group.valid_with_base? && group.save
        # add member to the group list
        page.insert_html :bottom, "group_#{group.id}_list", 
          :partial => 'groups/manage/member', :locals => {:group => group, :member => member}
        # remove from 'no group' list if in there
        page.remove "user_#{params[:member_name][group.id.to_s]}"
        page.call(:clearText, group.id.to_s)  # clear text
        page.replace_html("error_#{group.id}", "")  # clear errors
      else
        page.replace_html "error_#{group.id}",
          :partial => 'groups/error_single', :locals => { :objekt => group }
      end
    end
  end
  
  def remove_member
    return unless request.delete?
    
    group = Group.find(params[:group_id])
    member = group.memberships.find(params[:mbr_id])  # use group as scope
    student = member.user  # need to find user name to add to student list
    
    inviter = nil  # new inviter if member being removed is an inviter
    # randomly assign new inviter and rename submission file
    if member.inviter?  && group.memberships.count > 1
      @assignment = Assignment.find(params[:id])
      subm = @assignment.submission_by(student)
      inviter = group.memberships.first(:order => "created_at", 
        :conditions => ["status = 'accepted'"])
      subm.owner = inviter.user  # assign new_inviter as submission owner
      inviter.status = "inviter"
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
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    # Create new group for this assignment
    group = Group.new
    group.assignments << @assignment
    group.save(false) # skip validation requiring groups to have at least 1 member 
    render :update do |page|
      page.insert_html :top, "groups", 
        :partial => "groups/manage/group", :locals => { :group => group }
      page.call(:focusText, group.id.to_s)
    end
  end
  
  def remove_group
    return unless request.delete?
    # TODO remove groups for all assignment or just for the specific assignment?
    # TODO remove submissions in file system?
    group = Group.find(params[:group_id])
    render :update do |page|
      # update list of users not in group
      group.memberships.all(:include => :user).each do |member|
        student = member.user
        page.insert_html :bottom, "student_list",  
          "<li id='user_#{student.user_name}'>#{student.user_name}</li>"
      end
      page.visual_effect(:fade, "group_#{params[:group_id]}", :duration => 0.5)
      page.delay(0.5) { page.remove "group_#{params[:group_id]}"  }
    end
    group.destroy
  end
  
  def manage_new
    @assignment = Assignment.find(params[:id])
    @groups = @assignment.groups.all(:include => [:memberships])
    
    memberships = @groups.map { |g| g.memberships }
    user_groups = memberships.flatten.map { |m| m.user.id }
    @students = User.students.index_by { |s| s.id }
  end
  
end
