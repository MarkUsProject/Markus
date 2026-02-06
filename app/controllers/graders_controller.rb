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
      data = process_file_upload(['.csv'])
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      assignment = Assignment.find(params[:assignment_id])
      if params[:groupings]
        result = TaMembership.from_csv(assignment, data[:contents], params[:remove_existing_mappings])
      elsif params[:criteria]
        result = CriterionTaAssociation.from_csv(assignment, data[:contents], params[:remove_existing_mappings])
      end

      flash_csv_result(result)
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
    grader_ids = params[:graders] || []
    if grader_ids.blank? && params[:global_actions] != 'assign_sections'
      grader_ids = current_course.tas.joins(:user).where('users.user_name': params[:grader_user_names]).ids
      if grader_ids.blank?
        flash_now(:error, I18n.t('graders.select_a_grader'))
        head :bad_request
        return
      end
    end

    # It appears that the params[:graders] received is always an array of stringed integers instead of integers.
    # This is the case both from the React front-end (it sends id's as strings; this should be dealt with in
    # the future), as well as from the requests generated in the RSPEC tests, where it appears that array elements
    # (in request parameters) are automatically converted to strings for HTTP transmission.
    # This map handles the required conversion from stringed integers to integers.
    grader_ids.map!(&:to_i)

    if %w[assign random_assign].include? params[:global_actions]
      inactive_graders_hash =
        current_course.tas.joins(:user).where(roles: { hidden: true }).pluck(:id, :user_name)
                      .map { |x| [x[0], x[1]] }.to_h

      inactive_graders_for_flash = inactive_graders_hash.select { |k| grader_ids.include? k }

      grader_ids.reject! { |grader_id| inactive_graders_hash.key? grader_id }

      if inactive_graders_for_flash.size > 0
        flash_now(:error,
                  I18n.t('groups.invite_member.errors.inactive_grader',
                         user_names: inactive_graders_for_flash.values.join(', ')))
      end
    end

    case params[:current_table]
    when 'groups_table'
      if params[:global_actions] == 'assign_sections'
        assignments = params[:assignments]
        if assignments.blank?
          flash_now(:error, I18n.t('graders.select_a_grader'))
          head :bad_request
          return
        end
        grouping_hash = filter_grouping_by_section(assignments, @assignment)
      else
        grouping_ids = params[:groupings]
        if grouping_ids.blank?
          flash_now(:error, I18n.t('groups.select_a_group'))
          head :bad_request
          return
        end
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
          flash_now(:info, I18n.t('graders.group_submission_no_files'))
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
      when 'assign_sections'
        found_empty_submission = false
        filtered_grouping_hash = {}

        grouping_hash.each do |ta_id, group_ids|
          if params[:skip_empty_submissions] == 'true'
            filtered_grouping_ids = filter_empty_submissions(group_ids)
            if filtered_grouping_ids.count != group_ids.count
              found_empty_submission = true
            end
          else
            filtered_grouping_ids = group_ids
          end
          filtered_grouping_hash[ta_id] = filtered_grouping_ids
        end

        begin
          if found_empty_submission
            assign_graders_by_section(filtered_grouping_hash)
            flash_now(:info, I18n.t('graders.group_submission_no_files'))
          else
            assign_graders_by_section(grouping_hash)
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

  def assign_graders_by_section(grouping_hash)
    Grouping.assign_by_section(grouping_hash, @assignment)
  end

  def unassign_graders(grouping_ids, grader_ids)
    grader_membership_ids = TaMembership.where(grouping_id: grouping_ids, role_id: grader_ids).ids
    Grouping.unassign_tas(grader_membership_ids, grouping_ids, @assignment)
  end

  # Returns array of grouping ids with non empty submissions
  def filter_empty_submissions(grouping_ids)
    Submission.where(grouping_id: grouping_ids, is_empty: false, submission_version_used: true)
              .pluck(:grouping_id)
  end

  def filter_grouping_by_section(section_assignments, assignment)
    ta_groupings = {}

    section_assignments.each do |section_name, ta_id|
      grouping_ids = assignment.groupings.joins(:section)
                               .where(section: { name: section_name })
                               .ids

      ta_groupings[ta_id] = grouping_ids
    end

    ta_groupings
  end

  def implicit_authorization_target
    OpenStruct.new policy_class: GraderPolicy
  end
end
