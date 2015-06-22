class RubricsController < ApplicationController

  before_filter :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.rubric_criteria(order: 'position')
  end

  def edit
    @criterion = RubricCriterion.find(params[:id])
    render 'edit', formats: [:js]
  end

  def update
    @criterion = RubricCriterion.find(params[:id])
    unless @criterion.update_attributes(rubric_criterion_params)
      render :errors
      return
    end
    flash.now[:success] = I18n.t('criterion_saved_success')
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @criterion = RubricCriterion.new
    render 'new', formats: [:js]
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.rubric_criteria
    if @criteria.length > 0
      new_position = @criteria.last.position + 1
    else
      new_position = 1
    end
    @criterion = RubricCriterion.new
    @criterion.assignment = @assignment
    @criterion.weight = RubricCriterion::DEFAULT_WEIGHT
    @criterion.set_default_levels
    @criterion.position = new_position
    unless @criterion.update_attributes(rubric_criterion_params)
      @errors = @criterion.errors
      render 'add_criterion_error', formats: [:js]
      return
    end
    @criteria.reload
    render :create_and_edit
  end

  def destroy
    @criterion = RubricCriterion.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.rubric_criteria
    #delete all marks associated with this criterion
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
    render 'destroy', formats: [:js]
  end

  def download_csv
    @assignment = Assignment.find(params[:assignment_id])
    file_out = RubricCriterion.create_csv(@assignment)
    send_data(file_out, type: 'text/csv', filename: "#{@assignment.short_identifier}_rubric_criteria.csv", disposition: 'inline')
  end

  def download_yml
     assignment = Assignment.find(params[:assignment_id])
     file_out = assignment.export_rubric_criteria_yml
     send_data(file_out, type: 'text/plain', filename: "#{assignment.short_identifier}_rubric_criteria.yml", disposition: 'inline')
  end

  def csv_upload
    file = params[:csv_upload][:rubric]
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if request.post? && !file.blank?
      begin
        RubricCriterion.transaction do
          invalid_lines = []
          nb_updates = RubricCriterion.parse_csv(file, @assignment, invalid_lines, encoding)
          unless invalid_lines.empty?
            flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
          end
          if nb_updates > 0
            flash[:notice] = I18n.t('rubric_criteria.upload.success',
              nb_updates: nb_updates)
          end
        end
      rescue CSV::MalformedCSVError
        flash[:error] = t('csv.upload.malformed_csv')
      rescue ArgumentError
        flash[:error] = I18n.t('csv.upload.non_text_file_with_csv_extension')
      end
    end
    redirect_to action: 'index', id: @assignment.id
  end

  def yml_upload
    criteria_with_errors = ActiveSupport::OrderedHash.new
    assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    unless request.post?
      redirect_to action: 'index', id: assignment.id
      return
    end
    file = params[:yml_upload][:rubric]
    unless file.blank?
      begin
        rubrics = YAML::load(file.utf8_encode(encoding))
      rescue Psych::SyntaxError => e
        flash[:error] = I18n.t('rubric_criteria.upload.error') + '  ' +
           I18n.t('rubric_criteria.upload.syntax_error', error: "#{e}")
        redirect_to action: 'index', id: assignment.id
        return
      end
      unless rubrics
        flash[:error] = I18n.t('rubric_criteria.upload.error') +
          '  ' + I18n.t('rubric_criteria.upload.empty_error')
        redirect_to action: 'index', id: assignment.id
        return
      end
      successes = 0
      i = 1
      rubrics.each do |key|
        begin
          RubricCriterion.create_or_update_from_yml_key(key, assignment)
          successes += 1
        rescue RuntimeError => e
          #collect the names of the criterion that contains an error in it.
          criteria_with_errors[i] = key.at(0)
          i = i + 1
          flash[:error] = I18n.t('rubric_criteria.upload.syntax_error', error: "#{e}")
        end
      end

      bad_criteria_names = ''
      i = 0
      # Create a String from the OrderedHash of bad criteria seperated by commas.
      criteria_with_errors.each_value do |keys|
        if i == 0
          bad_criteria_names = keys
          i = i + 1
        else
          bad_criteria_names = bad_criteria_names + ', ' + keys
        end
      end

      if successes < rubrics.length
        flash[:error] = I18n.t('rubric_criteria.upload.error') + ' ' + bad_criteria_names
      end

      if successes > 0
        flash[:notice] = I18n.t('rubric_criteria.upload.success', nb_updates: successes)
      end
    end
    redirect_to action: 'index', assignment_id: assignment.id
  end

  # This method handles the drag/drop RubricCriteria sorting
  def update_positions
    unless request.post?
      render nothing: true
      return
    end

    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.rubric_criteria
    position = 0

    params[:criterion].each do |id|
      if id != ''
        position += 1
        RubricCriterion.update(id, position: position)
      end
    end
  end

  private

  def rubric_criterion_params
    params.require(:rubric_criterion).permit(:rubric_criterion_name,
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
                                             :weight)
  end
end
