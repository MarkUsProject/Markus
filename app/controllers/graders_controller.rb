# Manages actions relating to assigning graders.
class GradersController < ApplicationController
  # The names of the associations of groupings required by the view, which
  # should be eagerly loaded.
  GROUPING_ASSOC = [:group, :students,
                    { ta_memberships: :role, inviter: :section }].freeze
  # The names of the associations of criteria required by the view, which
  # should be eagerly loaded.
  CRITERION_ASSOC = [criterion_ta_associations: :ta].freeze

  before_action { authorize! }

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])

    respond_to do |format|
      format.html
      format.json do
        render json: @assignment.current_grader_data
      end
    end
  end

  def upload
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      assignment = Assignment.find(params[:assignment_id])
      if params[:groupings]
        result = TaMembership.from_csv(assignment, data[:file], params[:remove_existing_mappings])
      elsif params[:criteria]
        result = CriterionTaAssociation.from_csv(assignment, data[:file], params[:remove_existing_mappings])
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

  def grader_groupings_mapping
    assignment = Assignment.find(params[:assignment_id])
    groupings = assignment.groupings.includes(:group, :tas)

    file_out = MarkusCsv.generate(groupings) do |grouping|
      [grouping.group.group_name] + grouping.tas.map(&:user_name)
    end
    send_data file_out,
              type: 'text/csv',
              disposition: 'attachment',
              filename: "#{assignment.short_identifier}_grader_groupings_mapping.csv"
  end

  def grader_criteria_mapping
    assignment = Assignment.find(params[:assignment_id])
    criteria = assignment.ta_criteria.includes(:tas)

    file_out = MarkusCsv.generate(criteria) do |criterion|
      [criterion.name] + criterion.tas.map(&:user_name)
    end

    send_data file_out,
              type: 'text/csv',
              disposition: 'attachment',
              filename: "#{assignment.short_identifier}_grader_criteria_mapping.csv"
  end

  # These actions act on all currently selected graders & groups
  def global_actions
    @assignment = Assignment.find(params[:assignment_id])
    grader_ids = params[:graders]
    if grader_ids.blank?
      grader_ids = current_course.tas.joins(:user).where('users.user_name': params[:grader_user_names]).ids
      if grader_ids.blank?
        flash_now(:error, I18n.t('graders.select_a_grader'))
        head :bad_request
        return
      end
    end

    # '%w' syntax is a Ruby idiom that, preferred over ["...", "...", ...] syntax for its conciseness and readability
    # It represents an array of strings
    if %w[assign random_assign].include? params[:global_actions]
      inactive_graders = [] # used to filter the 'grader_ids' array and to throw a custom flash message error

      # Solving N+1 querying problem by executing the SQL query:
      # SELECT * FROM roles WHERE id IN (..., ..., ..., ...)
      # (thus making one database request in the beginning instead of one for each grader id)
      graders = Ta.where(id: grader_ids)

      # checking for inactive graders
      graders.each do |grader|
        if grader.hidden
          inactive_graders.push(grader)
        end
      end

      # Throw red flash message error if any inactive graders exist
      # Note that after this check we proceed with any 'active' graders (the survivors of graders_id)
      if inactive_graders.size > 0
        flash_now(:error,
                  I18n.t('groups.invite_member.errors.inactive_grader',
                         user_names: inactive_graders.map(&:user_name).join(', ')))
      end

      inactive_grader_ids = inactive_graders.map(&:id)

      # Removing id's (from grader_ids) corresponding to inactive graders
      # The 'reject' method removes all array elements for which the provided block returns true
      # The '!' indicates that it mutates the original array
      grader_ids.reject! { |grader_id| inactive_grader_ids.include? grader_id.to_i }

      # inactive_graders.each do |grader|
      #   grader_ids.de
      # end
      # # Reassigning grader_id to only include active graders
      # grader_ids = active_grader_ids
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
        begin
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
            flash_now(:info, I18n.t('graders.group_submission_no_files'))
            head :ok
          else
            assign_all_graders(grouping_ids, grader_ids)
          end
        rescue StandardError => e
          flash_now(:error, e.message)
          head :bad_request
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
        begin
          weights = params[:weightings].map { |weight| Float(weight) }
          if weights.sum == 0 || weights.any?(&:negative?)
            head :bad_request
            flash_now(:error, I18n.t('graders.number_error'))
            return
          elsif found_empty_submission
            randomly_assign_graders(filtered_grouping_ids, grader_ids, weights)
            flash_now(:info, I18n.t('graders.group_submission_no_files'))
          else
            randomly_assign_graders(grouping_ids, grader_ids, weights)
          end
        rescue StandardError => e
          head :bad_request
          flash_now(:error, e.message)
          return
        end
      end
    when 'criteria_table'
      positions = params[:criteria]
      criterion_ids = @assignment.criteria.where(position: positions).ids

      if criterion_ids.blank?
        flash_now(:error, I18n.t('graders.select_a_criterion'))
        head :bad_request
        return
      end

      case params[:global_actions]
      when 'assign'
        Criterion.assign_all_tas(criterion_ids, grader_ids, @assignment)
      when 'unassign'
        criterion_grader_ids = criterion_ids.flat_map do |id|
          @assignment.criterion_ta_associations
                     .where(criterion_id: id, ta_id: grader_ids)
                     .ids
        end
        Criterion.unassign_tas(criterion_grader_ids, @assignment)
      when 'random_assign'
        Criterion.randomly_assign_tas(criterion_ids, grader_ids, @assignment)
      end
    end
    head :ok
  end

  def grader_summary
    if current_role.student? || current_role.ta?
      redirect_to controller: 'assignments', action: 'index'
      return
    end
    @assignment = Assignment.find(params[:assignment_id])
    render :grader_summary
  end

  private

  def randomly_assign_graders(grouping_ids, grader_ids, weightings)
    Grouping.randomly_assign_tas(grouping_ids, grader_ids, weightings, @assignment)
  end

  # This helper is only expected to be invoked from within the global_actions method, which
  # filters 'grader_ids' to remove inactive graders (in the cases of assign and random_assign)
  def assign_all_graders(grouping_ids, grader_ids)
    Grouping.assign_all_tas(grouping_ids, grader_ids, @assignment)
  end

  def unassign_graders(grouping_ids, grader_ids)
    grader_membership_ids = TaMembership.where(grouping_id: grouping_ids, role_id: grader_ids).ids
    Grouping.unassign_tas(grader_membership_ids, grouping_ids, @assignment)
  end

  # Returns array of grouping ids with non empty submissions
  def filter_empty_submissions(grouping_ids)
    grouping_ids.select do |grouping_id|
      submission = Submission.find_by(grouping_id: grouping_id, submission_version_used: true)
      submission && !submission.is_empty
    end
  end

  def implicit_authorization_target
    OpenStruct.new policy_class: GraderPolicy
  end
end
