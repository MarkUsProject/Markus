class GroupsController < ApplicationController
  
  before_filter      :authorize,      :only => [:manage]
  
  def index
    @assignments = Assignment.all(:order => 'id')
  end
  
  # Group management functions ---------------------------------------------
  
  def creategroup
    @assignment = Assignment.find(params[:id])
    @groups = params[:groups]
    return unless request.post?
    
    # Create new group for this assignment
    @group = Group.new
    @group.assignments << @assignment
    
    # Set this user as inviter
    @group.add_member(current_user, 'inviter')
    unless params[:group] && params[:group][:single] == '1'
      users = params[:groups].values.map { |m| m['user_name'].strip  }
      @group.invite(users)  # invite members to this group
    end
    
    @group.save
  end
  
  # DEPRECATED Creates a group and invite members specified
  def creategroup_old
    # TODO verify user is not in a group, (they can't create anyways)
    @assignment = Assignment.find(params[:id])
    @groups = params[:groups]
    
    return unless request.post?
    
    # create a new group
    @group = form_new
    return unless @group.save
    @group.group_number = @group.id
    
    if params[:group] && params[:group]['individual'] == "1"
      # redirect to submit page if person is working alone
      @group.save
      redirect_to(:action => 'submit', :id => params[:id])
      return
    else
      # invite users to this group
      members = add_members(@group, params[:groups].values)
    
      # TODO we might not need this restriction. redirect instead to status page
      # check if we have enough members or has at least one member 
      # if not working individually
      group_min = @assignment.group_min - 1
      if members.length < group_min || group_min == 0
        @group.errors.add_to_base(
          "You need to have at least #{[group_min, 1].max} valid user name(s)")
      end
    end
    
    # check if we do not have any errors
    if @group.errors.empty? && members.all?(&:valid?)
      @group.save
      redirect_to(:action => 'status', :id => @assignment.id) if members.all?(&:save)
    else
      @group.destroy  # ugly, but necessary. use transactions next time?
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
    @assignment = Assignment.find_by_id(params[:id])
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
