class CriteriaController < ApplicationController
  include CriteriaHelper

  before_action :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.marking_started?
      flash_now(:notice, I18n.t('marking_started_warning'))
    end
    @criteria = @assignment.get_criteria
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.messages.released_marks'))
      head :bad_request
    end
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.messages.released_marks'))
      head :bad_request
      return
    end
    criterion_class = params[:criterion_type].constantize
    @criterion = criterion_class.new
    @criterion.set_default_levels if params[:criterion_type] == 'RubricCriterion'
    if @criterion.update(name: params[:new_criterion_prompt],
                             assignment_id: @assignment.id,
                             max_mark: params[:max_mark_prompt],
                             position: @assignment.next_criterion_position)
      flash_now(:success, t('flash.actions.create.success',
                            resource_name: criterion_class.model_name.human))
    else
      @criterion.errors.full_messages.each do |message|
        flash_message(:error, message)
      end
      head :unprocessable_entity
    end
  end

  def edit
    @criterion = params[:criterion_type].constantize.find(params[:id])
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.messages.released_marks'))
    end
  end

  def destroy
    @criterion = params[:criterion_type].constantize.find(params[:id])
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.messages.released_marks'))
      return
    end
    # Delete all marks associated with this criterion.
    @criterion.destroy
    flash_message(:success, t('flash.criteria.destroy.success'))
  end

  def update
    criterion_type = params[:criterion_type]
    @criterion = criterion_type.constantize.find(params[:id])
    @assignment = @criterion.assignment
    if @assignment.released_marks.any?
      flash_now(:error, t('criteria.errors.messages.released_marks'))
      head :bad_request
      return
    end
    if criterion_type == 'RubricCriterion'
      properly_updated = @criterion.update(rubric_criterion_params.except(:assignment_files))
      unless rubric_criterion_params[:assignment_files].nil?
        assignment_files = AssignmentFile.find(rubric_criterion_params[:assignment_files].select { |id| !id.empty? })
      end
    elsif criterion_type == 'FlexibleCriterion'
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
      params[:criterion].each_with_index do |type_id, index|

        type = type_id.match(/^[a-zA-Z]+/).to_s
        id   = type_id.match(/\d+/).to_s

        type.constantize.update(id, position: index + 1) unless id.blank?
      end
    end
  end

  def download_yml
    assignment = Assignment.find(params[:assignment_id])
    yml_criteria = {}
    assignment.get_criteria.each{ |criterion| yml_criteria = yml_criteria.merge(criterion.class.to_yml(criterion)) }
    send_data(yml_criteria.to_yaml.gsub("---\n", ''),
              type: 'text/plain',
              filename: "#{assignment.short_identifier}_criteria.yml",
              disposition: 'inline')
  end

  def upload_yml
    assignment = Assignment.find(params[:assignment_id])
    if assignment.released_marks.any?
      flash_message(:error, t('criteria.errors.messages.released_marks'))
      redirect_to action: 'index', id: assignment.id
      return
    end
    # Check for errors in the request or in the file uploaded.
    unless request.post?
      redirect_to action: 'index', id: assignment.id
      return
    end

    file = params[:yml_upload][:rubric]
    unless file.blank?
      begin
        encoding = params[:encoding]
        # Note: this parsing does not output entries with repeated names.
        criteria = YAML::load(file.utf8_encode(encoding))
      rescue Psych::SyntaxError => e
        flash_message(:error, I18n.t('criteria.upload.error.invalid_format') + '  ' +
                      I18n.t('upload_errors.syntax_error', error: "#{e}"))
        redirect_to action: 'index', id: assignment.id
        return
      end
      unless criteria
        flash_message(:error, I18n.t('criteria.upload.error.invalid_format') +
                      '  ' + I18n.t('criteria.upload.empty_error'))
        redirect_to action: 'index', id: assignment.id
        return
      end

      # Delete all current criteria for this assignment.
      assignment.get_criteria.each(&:destroy)

      # Create criteria based on the parsed data.
      load_criteria(criteria, assignment)
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
                                               assignment_files: [])
  end

  def rubric_criterion_params
    params.require(:rubric_criterion).permit(:name,
                                             :assignment,
                                             :position,
                                             :level_0_name,
                                             :level_0_description,
                                             :level_1_name,
                                             :level_1_description,
                                             :level_2_name,
                                             :level_2_description,
                                             :level_3_name,
                                             :level_3_description,
                                             :level_4_name,
                                             :level_4_description,
                                             :ta_visible,
                                             :peer_visible,
                                             assignment_files: []).to_h.deep_merge(params.require(:rubric_criterion)
                                                                           .permit(:max_mark).to_h)
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
