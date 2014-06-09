# Manages actions relating to assigning graders.
class GradersController < ApplicationController
  include GradersHelper

  # The names of the associations of groupings required by the view, which
  # should be eagerly loaded.
  GROUPING_ASSOC = [:group, :students,
                    ta_memberships: :user, inviter: :section]
  # The names of the associations of criteria required by the view, which
  # should be eagerly loaded.
  CRITERION_ASSOC = [:criterion_ta_associations]

  # Administrator
  # -
  before_filter      :authorize_only_for_admin

  def upload_dialog
    @assignment = Assignment.find(params[:assignment_id])
    render :partial => 'graders/modal_dialogs/upload_dialog',
           :handlers => [:rjs]
  end

  def download_dialog
    @assignment = Assignment.find(params[:assignment_id])
    render :partial => 'graders/modal_dialogs/download_dialog',
           :handlers => [:rjs]
  end

  def groups_coverage_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping])
    render :partial => 'graders/modal_dialogs/groups_coverage_dialog',
           :handlers => [:rjs]
  end

  def grader_criteria_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @grader = Ta.find(params[:grader])
    render :partial => 'graders/modal_dialogs/grader_criteria_dialog',
           :handlers => [:rjs]
  end


  def populate
    @assignment = Assignment.find(params[:assignment_id])
    groupings = groupings_with_assoc(@assignment)
    @table_rows = construct_table_rows(groupings, @assignment)
    render :populate, :formats => [:js] 
  end

  def populate_graders
    @assignment = Assignment.find(params[:assignment_id])
    graders = Ta.all
    @table_rows = construct_grader_table_rows(graders, @assignment)
  end

  def populate_criteria
    @assignment = Assignment.find(params[:assignment_id])
    criteria = criteria_with_assoc(@assignment)
    @table_rows = construct_criterion_table_rows(criteria, @assignment)
    render :populate_criteria, :formats => [:js] 
  end

  def set_assign_criteria
    @assignment = Assignment.find(params[:assignment_id])
    if params[:value] == 'true'
      @assignment.assign_graders_to_criteria = true
    else
      @assignment.assign_graders_to_criteria = false
    end
    @assignment.save
  end

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @sections = Section.all
  end

  # Assign TAs to Groupings via a csv file
  def csv_upload_grader_groups_mapping
    if !request.post? || params[:grader_mapping].nil?
      flash[:error] = I18n.t('csv.group_to_grader')
      redirect_to :action => 'index', :assignment_id => params[:assignment_id]
      return
    end

    invalid_lines = Grouping.assign_tas_by_csv(params[:grader_mapping].read,
                                               params[:assignment_id], params[:encoding])
    if invalid_lines.size > 0
      flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
    end
    redirect_to :action => 'index', :assignment_id => params[:assignment_id]
  end

  # Assign TAs to Criteria via a csv file
  def csv_upload_grader_criteria_mapping
    @assignment = Assignment.find(params[:assignment_id])
    if !request.post? || params[:grader_criteria_mapping].nil?
      flash[:error] = I18n.t('csv.criteria_to_grader')
      redirect_to :action => 'index', :assignment_id => params[:assignment_id]
      return
    end

    invalid_lines = @assignment.criterion_class.assign_tas_by_csv(
      params[:grader_criteria_mapping].read,
      params[:assignment_id],
      params[:encoding]
    )
    if invalid_lines.size > 0
      flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
    end
    redirect_to :action => 'index', :assignment_id => params[:assignment_id]
  end

  def download_grader_groupings_mapping
    assignment = Assignment.find(params[:assignment_id])
    groupings = groupings_with_assoc(assignment, includes: [:group, :tas])

    file_out = CSV.generate do |csv|
       groupings.each do |grouping|
         group_array = [grouping.group.group_name]
         # csv format is group_name, ta1_name, ta2_name, ... etc
         grouping.tas.each do |ta|
            group_array.push(ta.user_name)
         end
         csv << group_array
       end
     end

    send_data(file_out, :type => 'text/csv', :disposition => 'inline')
  end

  def download_grader_criteria_mapping
    assignment = Assignment.find(params[:assignment_id])
    criteria = criteria_with_assoc(assignment, includes: [:tas])

    file_out = CSV.generate do |csv|
       criteria.each do |criterion|
         criterion_array = [criterion.get_name]
         # csv format is criterion_name, ta1_name, ta2_name, ... etc
         criterion.tas.each do |ta|
            criterion_array.push(ta.user_name)
         end
         csv << criterion_array
       end
     end

    send_data(file_out, :type => 'text/csv', :disposition => 'inline')
  end

  def add_grader_to_grouping
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping_id],
                                :include => [:students, :tas, :group])
    grader = Ta.find(params[:grader_id])
    @grouping.add_tas(grader)
    @groupings_data = construct_table_rows([@grouping.reload],@assignment)
    @graders_data = construct_grader_table_rows([grader], @assignment)
    criteria = grader.get_criterion_associations_by_assignment(@assignment).map{|c| c.criterion}
    criteria.each do |criterion|
      criterion.save
    end
    @criteria_data = construct_criterion_table_rows(criteria, @assignment)
    render :add_grader_to_grouping, :formats => [:js] 
  end

  #These actions act on all currently selected graders & groups
  def global_actions
    grouping_ids = params[:groupings]
    grader_ids = params[:graders]
    criterion_ids = params[:criteria]

    case params[:current_table]
      when 'groups_table'
        @assignment = Assignment.find(params[:assignment_id])
        if params[:groupings].nil? or params[:groupings].size ==  0
         #if there is a global action than there should be a group selected
          if params[:global_actions]
              @global_action_warning = I18n.t('assignment.group.select_a_group')
              render :partial => 'shared/global_action_warning', :handlers => [:rjs]
              return
          end
        end
        case params[:global_actions]
          when 'assign'
            if params[:graders].nil? or params[:graders].size ==  0
              @global_action_warning = I18n.t('assignment.group.select_a_grader')
              render :partial => 'shared/global_action_warning', :handlers => [:rjs]
              return
            end
            assign_all_graders(grouping_ids, grader_ids)
            return
          when 'unassign'
            unassign_graders(params[:grader_memberships], grouping_ids)
            return
          when 'random_assign'
            if params[:graders].nil? or params[:graders].size ==  0
              @global_action_warning = I18n.t('assignment.group.select_a_grader')
              render :partial => 'shared/global_action_warning', :handlers => [:rjs]
              return
            end
            randomly_assign_graders(grouping_ids, grader_ids)
            return
        end
      when 'criteria_table'
        @assignment = Assignment.find(params[:assignment_id],
          :include => [{:groupings => [:students,
                {:tas => :criterion_ta_associations}, :group]}])
        if params[:criteria].nil? or params[:criteria].size ==  0
      #don't do anything if no criteria
          render :nothing => true
          return
        end
        criteria = criteria_with_assoc(@assignment,
                                       criterion_ids: criterion_ids)
        case params[:global_actions]
          when 'assign'
          if params[:graders].nil? or params[:graders].size ==  0
            #don't do anything if no graders
            render :nothing => true
            return
          end
            graders = Ta.where(:id => grader_ids)
            add_graders_to_criteria(criteria, graders)
            return
          when 'unassign'
            remove_graders_from_criteria(criteria, params)
            return
          when 'random_assign'
            if params[:graders].nil? or params[:graders].size ==  0
              #don't do anything if no graders
              render :nothing => true
              return
            end
            randomly_assign_graders_to_criteria(criteria, grader_ids)
            return
        end
    end
  end

  private

  # Returns a list of groupings with included associations.
  #
  #   # Include the tas asociation of grouping.
  #   groupings_with_assoc(a, :includes => [:tas])
  #   # Include all associations in GROUPING_ASSOC.
  #   groupings_with_assoc(a)
  def groupings_with_assoc(assignment, options = {})
    grouping_ids = options[:grouping_ids]
    includes = options[:includes] || GROUPING_ASSOC

    groupings = assignment.groupings.includes(includes)
    grouping_ids ? groupings.where(id: grouping_ids) : groupings
  end

  # Returns a list of criteria with included associations. See
  # #groupings_with_assoc.
  def criteria_with_assoc(assignment, options = {})
    criterion_ids = options[:criterion_ids]
    includes = options[:includes] || CRITERION_ASSOC

    criteria = assignment.get_criteria.includes(includes)
    criterion_ids ? criteria.where(id: criterion_ids) : criteria
  end

  def randomly_assign_graders_to_criteria(criteria, grader_ids)
    graders = Ta.where(:id => grader_ids)
    # Shuffle the criteria
    criteria = criteria.sort_by{rand}
    # Now, deal them out like cards...
    criteria.each_with_index do |criterion, index|
      # Choose the next grader to deal out to...
      grader = graders[index % graders.size]
      criterion.add_tas(grader)
      criterion.save
    end
    groupings = []
    graders.each do |grader|
      groupings.concat(grader.get_groupings_by_assignment(@assignment))
    end
    groupings = groupings.uniq
    groupings.each do |grouping|
      covered_criteria = grouping.all_assigned_criteria(grouping.tas)
      grouping.criteria_coverage_count = covered_criteria.length
      grouping.save
    end
    construct_all_rows(groupings, graders, criteria)
    render :modify_criteria, :formats => [:js] 
  end

  def randomly_assign_graders(grouping_ids, grader_ids)
    Grouping.randomly_assign_tas(grouping_ids, grader_ids, @assignment)
    render_grouping_modifications(grouping_ids, grader_ids)
  end

  def assign_all_graders(grouping_ids, grader_ids)
    Grouping.assign_all_tas(grouping_ids, grader_ids, @assignment)
    render_grouping_modifications(grouping_ids, grader_ids)
  end

  def add_graders_to_criteria(criteria, graders)
    criteria.each do |criterion|
      criterion.add_tas(graders)
      criterion.save
    end
    groupings = []
    graders.each do |grader|
      groupings.concat(grader.get_groupings_by_assignment(@assignment))
    end
    groupings = groupings.uniq
    groupings.each do |grouping|
      covered_criteria = grouping.all_assigned_criteria(grouping.tas)
      grouping.criteria_coverage_count = covered_criteria.length
      grouping.save
    end
    construct_all_rows(groupings, graders, criteria)
    render :modify_criteria, :formats => [:js] 
  end

  def remove_graders_from_criteria(criteria, params)
    all_graders = []
    criteria.each do |criterion|
      graders = criterion.tas.delete_if do |grader|
                  !params["#{criterion.id}_#{grader.user_name}"]
                end
      criterion.remove_tas(graders)
      criterion.save
      all_graders.concat(graders)
    end
    all_graders = all_graders.uniq
    groupings = []
    all_graders.each do |grader|
      groupings.concat(grader.get_groupings_by_assignment(@assignment))
    end
    groupings = groupings.uniq
    groupings.each do |grouping|
      covered_criteria = grouping.all_assigned_criteria(grouping.tas)
      grouping.criteria_coverage_count = covered_criteria.length
      grouping.save
    end
    construct_all_rows(groupings , all_graders, criteria)
    render :modify_criteria, :formats => [:js] 
  end

  def unassign_graders(grader_membership_ids, grouping_ids)
    Grouping.unassign_tas(grader_membership_ids, grouping_ids, @assignment)
    render_grouping_modifications(grouping_ids)
  end

  # Renders the grader, grouping and criterion table in response to
  # modifications to groupings.
  def render_grouping_modifications(grouping_ids, grader_ids = nil)
    groupings = groupings_with_assoc(@assignment, grouping_ids: grouping_ids)
    # Also update the various counts in graders and criteria table.
    graders = grader_ids ? Ta.where(id: grader_ids) : Ta.all
    criteria = criteria_with_assoc(@assignment)
    construct_all_rows(groupings, graders, criteria)
    render :modify_groupings, formats: [:js]
  end

  def construct_all_rows(groupings, graders, criteria)
    @groupings_data = construct_table_rows(groupings, @assignment)
    @graders_data = construct_grader_table_rows(graders, @assignment)
    if @assignment.assign_graders_to_criteria
      @criteria_data = construct_criterion_table_rows(criteria, @assignment)
    end
  end
end
