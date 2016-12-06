class CriteriaController < ApplicationController
  include CriteriaHelper

  before_filter :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.past_all_due_dates?
      flash_now(:notice, I18n.t('past_due_date_warning'))
    end
    @criteria = @assignment.get_criteria
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    criterion_class = params[:criterion_type].constantize
    @criterion = criterion_class.new
    @criterion.set_default_levels if params[:criterion_type] == 'RubricCriterion'
    unless @criterion.update(name: params[:new_criterion_prompt],
                             assignment_id: @assignment.id,
                             max_mark: params[:max_mark_prompt],
                             position: @assignment.next_criterion_position)
      @errors = @criterion.errors
      render :add_criterion_error
      return
    end
    @criteria = @assignment.get_criteria
    render :create_and_edit
  end

  def edit
    @criterion = params[:criterion_type].constantize.find(params[:id])
  end

  def destroy
    @criterion = params[:criterion_type].constantize.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.get_criteria
    # Delete all marks associated with this criterion.
    @criterion.destroy
    flash_message(:success, I18n.t('criterion_deleted_success'))
  end

  def update
    criterion_type = params[:criterion_type]
    @criterion = criterion_type.constantize.find(params[:id])
    if criterion_type == 'RubricCriterion'
      properly_updated = @criterion.update(rubric_criterion_params)
    elsif criterion_type == 'FlexibleCriterion'
      properly_updated = @criterion.update(flexible_criterion_params)
    else
      properly_updated = @criterion.update(checkbox_criterion_params)
    end
    unless properly_updated
      @errors = @criterion.errors
      render :errors
      return
    end
    flash_now(:success, t('criterion_saved_success'))
  end

  # Handles the drag/drop criteria sorting.
  def update_positions
    @assignment = Assignment.find(params[:assignment_id])

    ActiveRecord::Base.transaction do
      params[:criterion].each_with_index do |type_id, index|
        type, id = type_id.split(' ')
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
                      I18n.t('criteria.upload.syntax_error', error: "#{e}"))
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
                                               :peer_visible)
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
                                             :peer_visible).deep_merge(params.require(:rubric_criterion)
                                                                           .permit(:max_mark))
  end

  def checkbox_criterion_params
    params.require(:checkbox_criterion).permit(:name,
                                               :description,
                                               :position,
                                               :max_mark,
                                               :ta_visible,
                                               :peer_visible)
  end
end
