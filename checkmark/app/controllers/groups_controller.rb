class GroupsController < ApplicationController
  
  before_filter      :authorize,      :only => [:manage]
  # TODO filter (except index) to make sure assignment is a group assignment
  
  def index
    @assignments = Assignment.all(:order => 'id', 
      :conditions => ["group_max > 1"]) # only group assignments
  end
  
  # Group management functions ---------------------------------------------
  
  def creategroup
    @assignment = Assignment.find(params[:id])
    @group = current_user.group_for(@assignment)
    @groups = params[:groups]
    
    return unless request.post?
    
    # Create new group for this assignment
    @group = Group.new
    @group.assignments << @assignment
    
    # Set this user as inviter
    @group.add_member(current_user, 'inviter')
    unless params[:group] && params[:group][:single] == '1'
      if params[:groups]
        users = params[:groups].values.map { |m| m['user_name'].strip  }
        @group.invite(users)  # invite members to this group
      end
    end
    
    if @group.valid_with_base?
      redirect_to :controller => 'submissions', 
        :action => 'submit', :id => @assignment.id
    end
  end
  
  # Changes the user's member status for an assignment. 
  # If user rejects invite, user is removed from the group
  def join
    @assignment = Assignment.find(params[:id])
    group = current_user.group_for(@assignment.id)
    if !group || group.status(current_user) != 'pending'
      redirect_to :action => 'creategroup', :id => params[:id]
    end
    @inviter = group.inviter
    return unless request.post?
    
    if params[:accept]
      group.accept(current_user)
    elsif params[:reject]
      group.reject(current_user)
      redirect_to :action => 'creategroup', :id => params[:id]
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
