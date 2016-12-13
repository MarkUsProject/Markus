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

  layout 'assignment_content'

  def groups_coverage_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:grouping])
    render partial: 'graders/modal_dialogs/groups_coverage_dialog',
           handlers: [:erb]
  end

  def grader_criteria_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @grader = Ta.find(params[:grader])
    render partial: 'graders/modal_dialogs/graders_criteria_dialog',
           handlers: [:erb]
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
    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '" + I18n.t(:'graders.section') + "',
        sortable: true
      },"
    end
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])
    @sections = Section.order(:name)

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
    if params[:grader_mapping].nil?
      flash_message(flash[:error], I18n.t('csv.group_to_grader'))
    else
      result = MarkusCSV.parse(params[:grader_mapping].read,
                               encoding: params[:encoding]) do |row|
        raise CSVInvalidLineError if row.empty?
        grouping = Grouping.joins(:group)
                           .find_by(groups: { group_name: row.first },
                                    assignment_id: params[:assignment_id])
        raise CSVInvalidLineError if grouping.nil?

        grouping.add_tas_by_user_name_array(row.drop(1))
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    end
    redirect_to action: 'index', assignment_id: params[:assignment_id]
  end

  # Assign TAs to Criteria via a csv file
  def csv_upload_grader_criteria_mapping
    if params[:grader_criteria_mapping].nil?
      flash_message(:error, I18n.t('csv.criteria_to_grader'))
    else
      @assignment = Assignment.find(params[:assignment_id])
      result = MarkusCSV.parse(params[:grader_criteria_mapping].read,
                               encoding: params[:encoding]) do |row|
        raise CSVInvalidLineError if row.empty?
        @assignment.add_graders_to_criterion(row.first, row.drop(1))
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    end

    redirect_to action: 'index', assignment_id: params[:assignment_id]
  end

  def download_grader_groupings_mapping
    assignment = Assignment.find(params[:assignment_id])
    groupings = groupings_with_assoc(assignment, includes: [:group, :tas])

    file_out = MarkusCSV.generate(groupings) do |grouping|
      [grouping.group.group_name] + grouping.tas.map(&:user_name)
    end
    send_data(file_out,
              type: 'text/csv', disposition: 'inline',
              filename: 'grader_groupings_mapping.csv')
  end

  def download_grader_criteria_mapping
    assignment = Assignment.find(params[:assignment_id])
    criteria = criteria_with_assoc(assignment,
                                   includes: [criterion_ta_associations: :ta])

    file_out = MarkusCSV.generate(criteria) do |criterion|
      [criterion.name] + criterion.tas.map(&:user_name)
    end

    send_data(file_out,
              type: 'text/csv', disposition: 'inline',
              filename: 'grader_criteria_mapping.csv')
  end

  def add_grader_to_grouping
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.includes([:students, :tas, :group]).find(params[:grouping_id])
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
    criterion_ids_types = params[:criteria]

    case params[:current_table]
    when 'groups_table'
      case params[:global_actions]
      when 'assign'
        if grader_ids.blank?
          flash_now(:error, I18n.t('assignment.group.select_a_grader'))
          head 400
          return
        end        
        if params[:skip_empty_submissions] == 'true'
          # If the instructor wants to skip empty submissions, filter
          # groups with empty submissions into a new array
          filtered_grouping_ids = filter_empty_submissions(grouping_ids)
          if filtered_grouping_ids.count != grouping_ids.count
            found_empty_submission = true
          end
        end
        if found_empty_submission
          assign_all_graders(filtered_grouping_ids, grader_ids)
          flash_now(:info, I18n.t('assignment.group.group_submission_no_files'))
          head 200
        else
          assign_all_graders(grouping_ids, grader_ids)
          head :ok
        end
      when 'unassign'
        if params[:grader_memberships].blank?
          flash_now(:error, I18n.t('assignment.group.select_a_grader'))
          head 400
        else
          unassign_graders(params[:grader_memberships])
          head :ok
        end
      when 'random_assign'
        if grader_ids.blank?
          flash_now(:error, I18n.t('assignment.group.select_a_grader'))
          head 400
        else
          if params[:skip_empty_submissions] == 'true'
            filtered_grouping_ids = filter_empty_submissions(grouping_ids)
            if filtered_grouping_ids.count != grouping_ids.count
              found_empty_submission = true
            end
          end
          if found_empty_submission
            randomly_assign_graders(filtered_grouping_ids, grader_ids)
            flash_now(:info, I18n.t('assignment.group.group_submission_no_files'))
            head 200
          else
            randomly_assign_graders(grouping_ids, grader_ids)
            head :ok
          end
        end
      end
    when 'criteria_table'
      case params[:global_actions]
      when 'assign'
        if grader_ids.blank?
          flash_now(:error, I18n.t('assignment.group.select_a_grader'))
          head 400
        elsif criterion_ids_types.blank?
          flash_now(:error, I18n.t('assignment.group.select_a_criterion'))
          head 400
        else
          assign_all_graders_to_criteria(criterion_ids_types, grader_ids)
          head :ok
        end
      when 'unassign'
        if params[:criterion_associations].blank?
          flash_now(:error, I18n.t('assignment.group.select_a_grader'))
          head 400
        else
          # Gets criterion associations from params then
          # gets their criterion ids so we can update the
          # group counts.
          criterion_associations = CriterionTaAssociation.find(
            params[:criterion_associations]
          )
          criteria = criterion_associations.map do |criterion_assoc|
            criterion_assoc.criterion
          end.uniq
          criterion_ids_by_type = {}
          %w[RubricCriterion FlexibleCriterion CheckboxCriterion].each do |type|
            criterion_ids_by_type[type] =
              criteria.select { |crit| crit.class.to_s == type }
          end
          unassign_graders_from_criteria(criterion_associations, criterion_ids_by_type)
          head :ok
        end
      when 'random_assign'
        if grader_ids.blank?
          flash_now(:error, I18n.t('assignment.group.select_a_grader'))
          head 400
        elsif criterion_ids_types.blank?
          flash_now(:error, I18n.t('assignment.group.select_a_criterion'))
          head 400
        else
          randomly_assign_graders_to_criteria(criterion_ids_types, grader_ids)
          head :ok
        end
      end
    end
  end

  def grader_summary
    @current_user = current_user
    if @current_user.student? || @current_user.ta?
      redirect_to controller: 'assignments', action: 'index'
      return
    end
    @assignment = Assignment.find(params[:assignment_id])
    render :grader_summary, layout: 'content'
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

    criteria = assignment.get_criteria(:all, :all, includes: includes)
    criterion_ids ? criteria.select{ |criterion| criterion_ids.include?(criterion.id) } : criteria
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

  def unassign_graders_from_criteria(criterion_grader_ids, criterion_ids_by_type)
    Criterion.unassign_tas(criterion_grader_ids, criterion_ids_by_type, @assignment)
  end

  def unassign_graders(grader_membership_ids)
    grader_memberships = TaMembership.find(grader_membership_ids)
    grouping_ids = grader_memberships.map do |membership|
      membership.grouping.id
    end
    Grouping.unassign_tas(grader_membership_ids, grouping_ids, @assignment)
  end

  # Returns array of grouping ids with non empty submissions
  def filter_empty_submissions(grouping_ids)
    grouping_ids.select do |grouping_id|
      submission = Submission.find_by(grouping_id: grouping_id)
      submission && SubmissionFile.where(submission_id: submission.id).exists?
    end
  end
end
