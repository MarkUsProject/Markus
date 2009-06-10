class TaAssignmentsController < ApplicationController
  include TaAssignmentsHelper
  before_filter :authorize_only_for_admin

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
    # Find all of the groupings for the assignment
    @groupings = @assignment.groupings.all(:include => [:student_memberships])
    
    student_memberships = @groupings.map { |g| g.student_memberships }
    user_groups = student_memberships.flatten.map { |m| m.user.id }
    @students = Student.find(:all).index_by { |s| s.id }

    @tas = Ta.find(:all)
        
  end
  
  # This method finds all of the Groupings assigned for marking to this TA
  # and updates the page to show these Groupings.
  def focus_ta
    assignment_id = params[:id]
    ta_id = params[:ta_id]
    ta = Ta.find(ta_id)
    memberships = ta.memberships_for_assignment(assignment_id)
    render :update do |page|
      #insert the new mark into the bottom of the table and focus it
      page.call(:clear_show_ta_assignment)
      memberships.each do |membership|
        page.call(:show_ta_assignment, membership.grouping_id)
      end
    end
  end
  
  # List the mappings for this TA
  def list_by_ta(aid, tid)
  end
  
  # Assign a TA to the submissions
  # Allow for multiple TAs to be assigned.
  def assign
    @ta = Ta.find_by_id(params[:ta_id])
    @selectedGroupings = ActiveSupport::JSON.decode(params[:selected_groups])
    assignment_id = params[:id]

    @selectedGroupings.each do |grouping_id|
      if !@ta.is_assigned_to_grouping?(grouping_id)
        assign_ta_to_grouping(@ta.id, grouping_id) # Defined in ta_assignmients_helper
      end     
    end
    render :update do |page|
      #insert the new mark into the bottom of the table and focus it
      @selectedGroupings.each do |grouping_id|
        grouping = Grouping.find(grouping_id)
        page.replace_html("grouping_#{grouping.id}_assigned_tas", grouping.get_ta_names.join(', '))
        page.call(:grouping_is_assigned, grouping_id)
        page.call(:show_ta_assignment, grouping_id)
      end
      page.replace_html("ta_#{@ta.id}_membership_count", @ta.memberships_for_assignment(assignment_id).size)
    end   
  end

  # Remove a mapping of a TA and a group
  def unassign
    @ta = Ta.find_by_id(params[:ta_id])
    @selectedGroupings = ActiveSupport::JSON.decode(params[:selected_groups])
    assignment_id = params[:id]
    # It's likely that there are some Groupings with no TA assigned for marking
    # them.  We need to update the interface to reflect this, and so we'll need
    # a collection of grouping_ids for unassigned Groupings.
        
    unassigned_groupings = []
    @selectedGroupings.each do |grouping_id|
      if @ta.is_assigned_to_grouping?(grouping_id)
        ta_membership = @ta.memberships.find_by_grouping_id(grouping_id)
        ta_membership.destroy
        grouping = Grouping.find(grouping_id)
        if !grouping.has_ta_for_marking?
          unassigned_groupings.push(grouping)
        end
        
      end     
    end
    render :update do |page|
      #insert the new mark into the bottom of the table and focus it
      @selectedGroupings.each do |grouping_id|
        grouping = Grouping.find(grouping_id)
        page.replace_html("grouping_#{grouping.id}_assigned_tas", grouping.get_ta_names.join(', '))
        page.call(:hide_ta_assignment, grouping_id)
      end
      unassigned_groupings.each do |grouping|
        page.call(:grouping_is_not_assigned, grouping.id)
        #page.replace_html("grouping_#{grouping.id}_assigned_tas", 
      end
      page.replace_html("ta_#{@ta.id}_membership_count", @ta.memberships_for_assignment(assignment_id).size)
    end  
  end

end
