class CriteriaController < ApplicationController
  before_action { authorize! }

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
    @criterion = record
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:notice, t('criteria.errors.released_marks'))
    end
  end

  def destroy
    @criterion = record
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
    @criterion = record
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.released_marks'))
      head :bad_request
      return
    end
    if @criterion.is_a? RubricCriterion
      # update everything except levels and assignments
      properly_updated = @criterion.update(rubric_criterion_params.except(:assignment_files))
      unless rubric_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(rubric_criterion_params[:assignment_files].reject(&:empty?))
      end
    elsif @criterion.is_a? FlexibleCriterion
      properly_updated = @criterion.update(flexible_criterion_params.except(:assignment_files))
      unless flexible_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(flexible_criterion_params[:assignment_files].reject(&:empty?))
      end
    else
      properly_updated = @criterion.update(checkbox_criterion_params.except(:assignment_files))
      unless checkbox_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(checkbox_criterion_params[:assignment_files].reject(&:empty?))
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

    Criterion.transaction do
      params[:criterion].each_with_index do |id, index|
        found_criterion = @assignment.criteria.find(id)
        found_criterion.update(position: index + 1)
      end
    rescue StandardError
      flash_message(:error, t('criteria.errors.criteria_not_found'))
      raise ActiveRecord::Rollback
    end
    head :ok
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
      data = process_file_upload(['.yml'])
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      ApplicationRecord.transaction do
        successes = Criterion.upload_criteria_from_yaml(assignment, data[:contents])
        flash_message(:success, I18n.t('upload_success', count: successes)) if successes > 0
      rescue StandardError => e
        flash_message(:error, e.message)
        raise ActiveRecord::Rollback
      end
    end
    redirect_to action: 'index', assignment_id: assignment.id
  end

  private

  def flexible_criterion_params
    params.require(:flexible_criterion).permit(:name,
                                               :description,
                                               :position,
                                               :max_mark,
                                               :ta_visible,
                                               :peer_visible,
                                               :bonus,
                                               assignment_files: [])
  end

  def rubric_criterion_params
    params.require(:rubric_criterion).permit(:name,
                                             :assignment,
                                             :position,
                                             :ta_visible,
                                             :peer_visible,
                                             :max_mark,
                                             :bonus,
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
                                               :bonus,
                                               assignment_files: [])
  end

  protected

  def implicit_authorization_target
    Criterion
  end
end
