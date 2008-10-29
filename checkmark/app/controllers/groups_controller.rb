class GroupsController < ApplicationController
  
  before_filter      :authorize,      :only => [:manage]
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
          :action => 'submit_sample', :id => @assignment.id
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
      :action => 'submit_sample', :id => @assignment.id
  end
  
  # Remove rejected member
  def remove_member
    return unless request.delete?
    @group = current_user.group_for(params[:id]) # assert not nil
    
    return unless @group.inviter == current_user
    @group.remove_member(params[:member_id])
    render :update do |page|
      page.visual_effect(:fade, "mbr_#{params[:member_id]}")
    end
  end
  
  
  # Group administration functions -----------------------------------------

  # Gives a csv list of group members for a specific assignment
  # for each group, members are listed then the last submission time followed by used grace days
  # for students not in a group, only the user name is listed
  # groups with no submission has a beginning of epoch time as last submission time
  def manage
    @assignment = Assignment.find(params[:id])
    redirect_to :action => 'index' unless @assignment
    
    # process csv for all groups and students not in a group
    
    # join the list of all students with the group table, 
    # order by group number given a specified assignment
    
    select_stmt = "SELECT * "
    from_stmt = "FROM (SELECT * FROM groups WHERE groups.assignment_id = E'#{@assignment.id}') AS g "
    join_stmt = "RIGHT OUTER JOIN users AS u on u.id = g.user_id "
    where_stmt = "WHERE u.role = '#{User::STUDENT}' "
    order_stmt = "ORDER BY g.group_number ASC "
    
    @students = User.find_by_sql(select_stmt + from_stmt + join_stmt + where_stmt + order_stmt)
    
    @groups = []
    @students.group_by(&:group_number).each do |gn, members|
      if gn
        
        group = []
        last_submission = Time.at(0)
        members.each do |m|
          m.status == 'pending' ? @groups << m.user_name : group << m.user_name
          # get max of last submission date for each member
          if last_submission
            submitted_at = Submission.last_submission(m, gn, @assignment)
            last_submission = [last_submission, submitted_at].max
          else
            last_submission = m.submitted_at
          end
        end
        
        # append last submission time and used grace days
        group << Submission.get_version(last_submission)
        group << Submission.get_used_grace_days(last_submission, @assignment)
        @groups.insert(0, group)
      else
        members.each { |m| @groups << [m.user_name] }
      end
    end
  end
  
end
