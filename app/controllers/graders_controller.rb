# Manages actions relating to assigning graders.
class GradersController < ApplicationController
  # The names of the associations of groupings required by the view, which
  # should be eagerly loaded.
  GROUPING_ASSOC = [:group, :students,
                    ta_memberships: :user, inviter: :section]
  # The names of the associations of criteria required by the view, which
  # should be eagerly loaded.
  CRITERION_ASSOC = [criterion_ta_associations: :ta]

  # Administrator
  # -
  before_action :authorize_only_for_admin

  layout 'assignment_content'

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

    respond_to do |format|
      format.html
      format.json do
        render json: @assignment.current_grader_data
      end
    end
  end

  # Assign TAs to Groupings via a csv file
  def csv_upload_grader_groups_mapping
    if params[:grader_mapping].nil?
      flash_message(flash[:error], I18n.t('csv.group_to_grader'))
    else
      assignment = Assignment.find(params[:assignment_id])
      if params[:remove_existing_mappings]
        Repository.get_class.update_permissions_after do
          TaMembership.joins(:grouping)
            .where(groupings: { assignment_id: assignment.id })
            .delete_all
        end
      end
      new_ta_memberships = []
      groupings = {}
      graders = {}
      assignment.groupings.includes(:group).find_each do |g|
        groupings[g.group.group_name] = g.id
      end
      Ta.find_each do |ta|
        graders[ta.user_name] = ta.id
      end
      result = MarkusCSV.parse(params[:grader_mapping].read,
                               encoding: params[:encoding]) do |row|
        raise CSVInvalidLineError if row.empty?
        raise CSVInvalidLineError if groupings[row[0]].nil?

        row.drop(1).each do |grader_name|
          unless graders[grader_name].nil?
            new_ta_memberships << TaMembership.new(
                                    grouping_id: groupings[row[0]],
                                    user_id: graders[grader_name]
            )
          end
        end
      end
      Repository.get_class.update_permissions_after do
        TaMembership.import new_ta_memberships, validate: false
      end

      # Recompute criteria associations
      if assignment.assign_graders_to_criteria
        Grouping.update_criteria_coverage_counts(
          assignment,
          new_ta_memberships.map { |x| x[:grouping_id] }
        )
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

  #These actions act on all currently selected graders & groups
  def global_actions
    @assignment = Assignment.find(params[:assignment_id])
    grader_ids = params[:graders]
    if grader_ids.blank?
      grader_ids = Ta.where(user_name: params[:grader_user_names]).pluck(:id)
      if grader_ids.blank?
        flash_now(:error, I18n.t('assignment.group.select_a_grader'))
        head :bad_request
        return
      end
    end

    case params[:current_table]
    when 'groups_table'
      grouping_ids = params[:groupings]
      if grouping_ids.blank?
        flash_now(:error, I18n.t('groups.select_a_group'))
        head :bad_request
        return
      end

      case params[:global_actions]
      when 'assign'
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
        end
      when 'unassign'
        unassign_graders(grouping_ids, grader_ids)
      when 'random_assign'
        if params[:skip_empty_submissions] == 'true'
          filtered_grouping_ids = filter_empty_submissions(grouping_ids)
          if filtered_grouping_ids.count != grouping_ids.count
            found_empty_submission = true
          end
        end
        if found_empty_submission
          randomly_assign_graders(filtered_grouping_ids, grader_ids)
          flash_now(:info, I18n.t('assignment.group.group_submission_no_files'))
        else
          randomly_assign_graders(grouping_ids, grader_ids)
        end
      end
    when 'criteria_table'
      positions = params[:criteria]
      # TODO: simplify data format interface between here and Criterion#assign_tas.
      criterion_ids_types =
        @assignment.rubric_criteria.where(position: positions).pluck(:id).map { |id| [id, 'RubricCriterion'] } +
          @assignment.flexible_criteria.where(position: positions).pluck(:id).map { |id| [id, 'FlexibleCriterion'] } +
          @assignment.checkbox_criteria.where(position: positions).pluck(:id).map { |id| [id, 'CheckboxCriterion'] }
      if criterion_ids_types.blank?
        flash_now(:error, I18n.t('assignment.group.select_a_criterion'))
        head :bad_request
        return
      end

      case params[:global_actions]
      when 'assign'
        assign_all_graders_to_criteria(criterion_ids_types, grader_ids)
      when 'unassign'
        # Gets criterion associations from params then
        # gets their criterion ids so we can update the
        # group counts.
        criterion_associations = []
        criterion_ids_by_type = {
          RubricCriterion: [],
          FlexibleCriterion: [],
          CheckboxCriterion: []
        }

        criterion_ids_types.each do |id, type|
          criterion_associations.concat(@assignment.criterion_ta_associations
                                                   .where(criterion_id: id, criterion_type: type, ta_id: grader_ids)
                                                   .pluck(:id))
          criterion_ids_by_type[type.to_sym] << id
        end
        unassign_graders_from_criteria(criterion_associations, criterion_ids_by_type)
      when 'random_assign'
        randomly_assign_graders_to_criteria(criterion_ids_types, grader_ids)
      end
    end
    head :ok
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

  def unassign_graders(grouping_ids, grader_ids)
    grader_membership_ids = TaMembership.where(grouping_id: grouping_ids, user_id: grader_ids).pluck(:id)
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
