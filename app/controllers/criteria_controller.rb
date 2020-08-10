class CriteriaController < ApplicationController
  before_action :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.marking_started?
      flash_now(:notice, I18n.t('assignments.due_date.marking_started_warning'))
    end
    @criteria = @assignment.criteria
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.released_marks'))
      head :bad_request
    end
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.released_marks'))
      head :bad_request
      return
    end
    @criterion = Criterion.new(
      type: params[:criterion_type],
      name: params[:new_criterion_prompt],
      assignment: @assignment,
      max_mark: params[:max_mark_prompt],
      position: @assignment.next_criterion_position
    )
    @criterion.set_default_levels if @criterion.is_a? RubricCriterion

    if @criterion.save
      flash_now(:success, t('flash.actions.create.success',
                            resource_name: @criterion.class.model_name.human))
    else
      @criterion.errors.full_messages.each do |message|
        flash_message(:error, message)
      end
      head :unprocessable_entity
    end
  end

  def edit
    @criterion = Criterion.find(params[:id])
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.released_marks'))
    end
  end

  def destroy
    @criterion = Criterion.find(params[:id])
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.released_marks'))
      return
    end
    # Delete all marks associated with this criterion.
    @criterion.destroy
    flash_message(:success, t('flash.criteria.destroy.success'))
  end

  def update
    @criterion = Criterion.find(params[:id])
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.released_marks'))
      head :bad_request
      return
    end
    if @criterion.is_a? RubricCriterion
      properly_updated = @criterion.update(rubric_criterion_params.except(:assignment_files))
      unless rubric_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(rubric_criterion_params[:assignment_files].select { |id| !id.empty? })
      end
    elsif @criterion.is_a? FlexibleCriterion
      properly_updated = @criterion.update(flexible_criterion_params.except(:assignment_files))
      unless flexible_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(flexible_criterion_params[:assignment_files].select { |id| !id.empty? })
      end
    else
      properly_updated = @criterion.update(checkbox_criterion_params.except(:assignment_files))
      unless checkbox_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(checkbox_criterion_params[:assignment_files].select { |id| !id.empty? })
      end
    end
    # delete old associated criteria_assignment_files_join
    old_criteria_assignment_files_join = @criterion.criteria_assignment_files_joins
    old_criteria_assignment_files_join.destroy_all
    # create new corresponding criteria_assignment_files_join
    assignment_files.to_a.each do |assignment_file|
      @criterion.criteria_assignment_files_joins.create(
        assignment_file: assignment_file
      )
    end
    if properly_updated
      flash_now(:success, t('flash.actions.update.success',
                            resource_name: @criterion.class.model_name.human))
    else
      @criterion.errors.full_messages.each do |message|
        flash_message(:error, message)
      end
      head :unprocessable_entity
    end
  end

  # Handles the drag/drop criteria sorting.
  def update_positions
    @assignment = Assignment.find(params[:assignment_id])

    ApplicationRecord.transaction do
      params[:criterion].each_with_index do |id, index|
        Criterion.update(id, position: index + 1) unless id.blank?
      end
    end
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    criteria = assignment.criteria
    yml_criteria = criteria.reduce({}) { |a, b| a.merge b.to_yml }
    send_data yml_criteria.to_yaml,
              filename: "#{assignment.short_identifier}_criteria.yml",
              disposition: 'attachment'
  end

  def upload
    assignment = Assignment.find(params[:assignment_id])
    if assignment.released_marks.any?
      flash_message(:error, t('criteria.errors.released_marks'))
      redirect_to action: 'index', id: assignment.id
      return
    end

    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.yml'
        ApplicationRecord.transaction do
          assignment.criteria.destroy_all

          # Create criteria based on the parsed data.
          successes = 0
          pos = 1
          crit_format_errors = []
          data[:contents].each do |criterion_yml|
            type = criterion_yml[1]['type']
            begin
              if type.casecmp('rubric') == 0
                criterion = RubricCriterion.load_from_yml(criterion_yml)
              elsif type.casecmp('flexible') == 0
                criterion = FlexibleCriterion.load_from_yml(criterion_yml)
              elsif type.casecmp('checkbox') == 0
                criterion = CheckboxCriterion.load_from_yml(criterion_yml)
              else
                raise RuntimeError
              end

              criterion.assessment_id = assignment.id
              criterion.position = pos
              criterion.save!
              pos += 1
              successes += 1
            rescue ActiveRecord::RecordInvalid # E.g., both visibility options are false.
              crit_format_errors << criterion_yml[0]
            rescue RuntimeError # An error occurred.
              crit_format_errors << criterion_yml[0]
            end
          end
          unless crit_format_errors.empty?
            flash_message(:error, "#{I18n.t('criteria.errors.invalid_format')} #{crit_format_errors.join(', ')}")
            raise ActiveRecord::Rollback
          end
          if successes > 0
            flash_message(:success,
                          I18n.t('upload_success', count: successes))
          end
        end
        reset_results_total_mark assignment.id
      end
    end
    redirect_to action: 'index', assignment_id: assignment.id
  end

  private

  # Resets the total mark for all results for the given assignment with id +assessment_id+.
  def reset_results_total_mark(assessment_id)
    Result.joins(submission: :grouping)
          .where('submissions.submission_version_used': true, 'groupings.assessment_id': assessment_id)
          .each do |result|
      result.update(marking_state: Result::MARKING_STATES[:incomplete])
      result.update_total_mark
    end
  end

  def flexible_criterion_params
    params.require(:flexible_criterion).permit(:name,
                                               :description,
                                               :position,
                                               :max_mark,
                                               :ta_visible,
                                               :peer_visible,
                                               assignment_files: [])
  end

  def rubric_criterion_params
    params.require(:rubric_criterion).permit(:name,
                                             :assignment,
                                             :position,
                                             :ta_visible,
                                             :peer_visible,
                                             :max_mark,
                                             levels_attributes: [:id, :name, :mark, :description, :_destroy],
                                             assignment_files: [])
  end

  def checkbox_criterion_params
    params.require(:checkbox_criterion).permit(:name,
                                               :description,
                                               :position,
                                               :max_mark,
                                               :ta_visible,
                                               :peer_visible,
                                               assignment_files: [])
  end
end
