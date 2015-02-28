# Manages actions relating to assigning graders.
class GradersController < ApplicationController
  include GradersHelper

  # The names of the associations of groupings required by the view, which
  # should be eagerly loaded.
  GROUPING_ASSOC = [:group, :students,
                    ta_memberships: :user, inviter: :section]
  # The names of the associations of criteria required by the view, which
  # should be eagerly loaded.
  CRITERION_ASSOC = [criterion_ta_associations: :ta]

  # Administrator
  # -
  before_filter      :authorize_only_for_admin

  def upload_dialog
    @assignment = Assignment.find(params[:assignment_id])
    render partial: 'graders/modal_dialogs/upload_dialog',
           handlers: [:rjs]
  end

  def download_dialog
    @assignment = Assignment.find(params[:assignment_id])
    render partial: 'graders/modal_dialogs/download_dialog',
           handlers: [:rjs]
  end

  def groups_coverage_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping])
    render partial: 'graders/modal_dialogs/groups_coverage_dialog',
           handlers: [:rjs]
  end

  def grader_criteria_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @grader = Ta.find(params[:grader])
    render partial: 'graders/modal_dialogs/grader_criteria_dialog',
           handlers: [:rjs]
  end

  def set_assign_criteria
    @assignment = Assignment.find(params[:assignment_id])
    if params[:value] == 'true'
      @assignment.assign_graders_to_criteria = true
    else
      @assignment.assign_graders_to_criteria = false
    end
    @assignment.save
    head :ok
  end

  def index
    @assignment = Assignment.find(params[:assignment_id])
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])
    @sections = Section.all

    assign_to_criteria = @assignment.assign_graders_to_criteria
    if assign_to_criteria
      graders_table_info = get_graders_table_info_with_criteria(@assignment)
      groups_table_info = get_groups_table_info_with_criteria(@assignment)
    else
      graders_table_info = get_graders_table_info_no_criteria(@assignment)
      groups_table_info = get_groups_table_info_no_criteria(@assignment)
    end
    # better to use a hash?
    render json: [assign_to_criteria, @sections,
                  graders_table_info, groups_table_info]
  end

  # Assign TAs to Groupings via a csv file
  def csv_upload_grader_groups_mapping
    if !request.post? || params[:grader_mapping].nil?
      flash[:error] = I18n.t('csv.group_to_grader')
      redirect_to action: 'index', assignment_id: params[:assignment_id]
      return
    end

    invalid_lines = Grouping.assign_tas_by_csv(params[:grader_mapping].read,
                                               params[:assignment_id], params[:encoding])
    if invalid_lines.size > 0
      flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
    end
    redirect_to action: 'index', assignment_id: params[:assignment_id]
  end

  # Assign TAs to Criteria via a csv file
  def csv_upload_grader_criteria_mapping
    @assignment = Assignment.find(params[:assignment_id])
    if !request.post? || params[:grader_criteria_mapping].nil?
      flash[:error] = I18n.t('csv.criteria_to_grader')
      redirect_to action: 'index', assignment_id: params[:assignment_id]
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
    redirect_to action: 'index', assignment_id: params[:assignment_id]
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

    send_data(file_out, type: 'text/csv', disposition: 'inline')
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

    send_data(file_out, type: 'text/csv', disposition: 'inline')
  end

  def add_grader_to_grouping
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping_id],
                                include: [:students, :tas, :group])
    grader = Ta.find(params[:grader_id])
    @grouping.add_tas(grader)
    criteria = grader.get_criterion_associations_by_assignment(@assignment).map{|c| c.criterion}
    criteria.each do |criterion|
      criterion.save
    end
    head :ok
  end

  #These actions act on all currently selected graders & groups
  def global_actions
    @assignment = Assignment.find(params[:assignment_id])
    grouping_ids = params[:groupings]
    grader_ids = params[:graders]
    criterion_ids = params[:criteria]

    case params[:current_table]
    when 'groups_table'
      case params[:global_actions]
      when 'assign'
        if grader_ids.blank?
          render text: I18n.t('assignment.group.select_a_grader'), status: 400
        else
          assign_all_graders(grouping_ids, grader_ids)
          head :ok
        end
      when 'unassign'
        if params[:grader_memberships].blank?
          render text: I18n.t('assignment.group.select_a_grader'), status: 400
        else
          unassign_graders(params[:grader_memberships])
          head :ok
        end
      when 'random_assign'
        if grader_ids.blank?
          render text: I18n.t('assignment.group.select_a_grader'), status: 400
        else
          randomly_assign_graders(grouping_ids, grader_ids)
          head :ok
        end
      end
    when 'criteria_table'
      case params[:global_actions]
      when 'assign'
        if grader_ids.blank?
          render text: I18n.t('assignment.group.select_a_grader'), status: 400
        else
          assign_all_graders_to_criteria(criterion_ids, grader_ids)
          head :ok
        end
      when 'unassign'
        if params[:criterion_associations].blank?
          render text: I18n.t('assignment.group.select_a_grader'), status: 400
        else
          # Gets criterion associations from params then
          # gets their criterion ids so we can update the
          # group counts.
          criterion_associations = CriterionTaAssociation.find(
            params[:criterion_associations]
          )
          criterion_ids = criterion_associations.map do |criterion_assoc|
            criterion_assoc.criterion
          end.uniq
          unassign_graders_from_criteria(criterion_associations, criterion_ids)
          head :ok
        end
      when 'random_assign'
        if grader_ids.blank?
          render text: I18n.t('assignment.group.select_a_grader'), status: 400
        else
          randomly_assign_graders_to_criteria(criterion_ids, grader_ids)
          head :ok
        end
      end
    end
  end

  private

  # Returns a list of groupings with included associations.
  #
  #   # Include the tas asociation of grouping.
  #   groupings_with_assoc(a, includes: [:tas])
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

  def randomly_assign_graders_to_criteria(criterion_ids, grader_ids)
    Criterion.randomly_assign_tas(criterion_ids, grader_ids, @assignment)
  end

  def randomly_assign_graders(grouping_ids, grader_ids)
    Grouping.randomly_assign_tas(grouping_ids, grader_ids, @assignment)
  end

  def assign_all_graders(grouping_ids, grader_ids)
    Grouping.assign_all_tas(grouping_ids, grader_ids, @assignment)
  end

  def assign_all_graders_to_criteria(criterion_ids, grader_ids)
    Criterion.assign_all_tas(criterion_ids, grader_ids, @assignment)
  end

  def unassign_graders_from_criteria(criterion_grader_ids, criterion_ids)
    Criterion.unassign_tas(criterion_grader_ids, criterion_ids, @assignment)
  end

  def unassign_graders(grader_membership_ids)
    grader_memberships = TaMembership.find(grader_membership_ids)
    grouping_ids = grader_memberships.map do |membership|
      membership.grouping.id
    end
    Grouping.unassign_tas(grader_membership_ids, grouping_ids, @assignment)
  end
end
