class TaAssignmentsController < ApplicationController

  before_filter :authorize

  # Grab the list of assignment to be marked
  def index
    @assignments = Assignment.all(:order => :id)
  end

  # List the submission for this assignment
  # For each submission, identify the groups
  # Recall that for individual assignments, each individual is a group of 1
  # TODO: test group submission, test individual submission
  def list

    # Find the assignment given the id
    @assignment = Assignment.find(params[:id])
    # Find all the groups for the assignment
    @groups = @assignment.groups.all(:include => [:memberships])
    
    memberships = @groups.map { |g| g.memberships }
    user_groups = memberships.flatten.map { |m| m.user.id }
    @students = User.students.index_by { |s| s.id }

    @tas = User.tas
        
  end

  # List the mappings for this TA
  def list_by_ta(aid, tid)
  end
  
  # Assign a TA to the submissions
  # Allow for multple TAs to be assigned.
  def assign

    @ta = User.find_by_id(params[:ta_id])
    @selectedGroups = ActiveSupport::JSON.decode(params[:selected_groups])

    success = 0

    @selectedGroups.each do |group|
      
      # TODO: Create only if the {user_id, group_id, assignment_id}
      # In new model: Mapping.find_or_create_by_tid_gid(@ta.id, gid):
      
      ta_assignment = Grade.new
      ta_assignment.user_id = @ta.id
      ta_assignment.group_id = group
      if (ta_assignment.save) then success = success + 1 end
      
    end
    
    if (success > 0)
      output = {'status' => 'OK'}
    else
      output = {'status' => 'error'}
    end
    
    render :json => output.to_json
    
  end

  # Remove a mapping of a TA and a group
  def remove
  end

end
