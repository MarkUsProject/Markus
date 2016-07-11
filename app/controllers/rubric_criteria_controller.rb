class RubricCriteriaController < ApplicationController

  before_filter :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.get_criteria.order(:position)
  end

  def edit
    @criterion = RubricCriterion.find(params[:id])
    render 'criteria/edit', formats: [:js], handlers: [:erb]
  end

  def update
    begin
      @criterion = RubricCriterion.find(params[:id])
      unless @criterion.update(rubric_criterion_params.deep_merge(params.require(:rubric_criterion)
                                                                      .permit(:max_mark)
                                                                      .transform_values { |x|  (Float(x) * 4).to_s }))
        @errors = @criterion.errors
        render 'criteria/errors', formats: [:js], handlers: [:erb]
        return
      end
    rescue ArgumentError
      flash.now[:error] = t('weight_not_number')
      return
    end
    flash.now[:success] = t('criterion_saved_success')
    render 'criteria/update', formats: [:js], handlers: [:erb]
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.get_criteria
    @criterion = RubricCriterion.new
    @criterion.assignment = @assignment
    @criterion.max_mark = RubricCriterion::DEFAULT_MAX_MARK
    @criterion.set_default_levels
    @criterion.position = @assignment.next_criterion_position
    unless @criterion.update_attributes(rubric_criterion_params)
      @errors = @criterion.errors
      render 'criteria/add_criterion_error', formats: [:js], handlers: [:erb]
      return
    end
    @criteria.reload
    render 'criteria/create_and_edit', formats: [:js], handlers: [:erb]
  end

  def destroy
    @criterion = RubricCriterion.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.get_criteria
    #delete all marks associated with this criterion
    @criterion.destroy
    flash[:success] = I18n.t('criterion_deleted_success')
    render 'criteria/destroy', formats: [:js], handlers: [:erb]
  end

  def download_csv
    @assignment = Assignment.find(params[:assignment_id])
    file_out = MarkusCSV.generate(@assignment.get_criteria) do |criterion|
      criterion_array = [criterion.name, criterion.max_mark]
      (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
        criterion_array.push(criterion['level_' + i.to_s + '_name'])
      end
      (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
        criterion_array.push(criterion['level_' + i.to_s + '_description'])
      end
      criterion_array
    end
    send_data(file_out,
              type: 'text/csv',
              filename: "#{@assignment.short_identifier}_rubric_criteria.csv",
              disposition: 'attachment')
  end

  def download_yml
     assignment = Assignment.find(params[:assignment_id])
     file_out = assignment.export_rubric_criteria_yml
     send_data(file_out, type: 'text/plain', filename: "#{assignment.short_identifier}_rubric_criteria.yml", disposition: 'inline')
  end

  def csv_upload
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if params[:csv_upload] && params[:csv_upload][:rubric]
      file = params[:csv_upload][:rubric]
      result = RubricCriterion.transaction do
        MarkusCSV.parse(file.read, encoding: encoding) do |row|
          next if CSV.generate_line(row).strip.empty?
          RubricCriterion.create_or_update_from_csv_row(row, @assignment)
        end
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
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
        rubric_criteria = YAML::load(file.utf8_encode(encoding))
      rescue Psych::SyntaxError => e
        flash[:error] = t('rubric_criteria.upload.error') + '  ' +
            I18n.t('rubric_criteria.upload.syntax_error', error: "#{e}")
        redirect_to action: 'index', id: assignment.id
        return
      end
      unless rubric_criteria
        flash[:error] = t('rubric_criteria.upload.error') +
          '  ' + I18n.t('rubric_criteria.upload.empty_error')
        redirect_to action: 'index', id: assignment.id
        return
      end
      successes = 0
      i = 1
      rubric_criteria.each do |key|
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

      if successes < rubric_criteria.length
        flash[:error] = t('rubric_criteria.upload.error') + ' ' + bad_criteria_names
      end

      if successes > 0
        flash[:notice] = t('rubric_criteria.upload.success', nb_updates: successes)
      end
    end
    redirect_to action: 'index', assignment_id: assignment.id
  end

  private

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
                                             :peer_visible)
  end
end
