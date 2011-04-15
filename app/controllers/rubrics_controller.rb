class RubricsController < ApplicationController

  before_filter      :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:id])
    @criteria = @assignment.rubric_criteria(:order => 'position')
  end

  def edit
    @criterion = RubricCriterion.find(params[:id])
  end

  def update
    @criterion = RubricCriterion.find(params[:id])
    if !@criterion.update_attributes(params[:rubric_criterion])
      render :action => 'errors'
      return
    end
    flash.now[:success] = I18n.t('criterion_saved_success')
  end

  def new
    @assignment = Assignment.find(params[:id])
    if !request.post?
      return
    else
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
      if !@criterion.update_attributes(params[:rubric_criterion])
        @errors = @criterion.errors
        render :action => 'add_criterion_error'
        return
      end
      @criteria.reload
      render :action => 'create_and_edit'
    end
  end

  def delete
    return unless request.delete?
    @criterion = RubricCriterion.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.rubric_criteria
    #delete all marks associated with this criterion
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
  end

  def download_csv
    @assignment = Assignment.find(params[:id])
    file_out = RubricCriterion.create_csv(@assignment)
    send_data(file_out, :type => "text/csv", :filename => "#{@assignment.short_identifier}_rubric_criteria.csv", :disposition => "inline")
  end

  def download_yml
     @assignment = Assignment.find(params[:id])
     file_out = @assignment.export_rubric_criteria_yml
     send_data(file_out, :type => "text/myl", :filename => "#{@assignment.short_identifier}_rubric_criteria.yml", :disposition => "inline")
  end

  def csv_upload
    file = params[:csv_upload][:rubric]
    @assignment = Assignment.find(params[:id])
    if request.post? && !file.blank?
      begin
        RubricCriterion.transaction do
          invalid_lines = []
          nb_updates = RubricCriterion.parse_csv(file, @assignment, invalid_lines)
          if !invalid_lines.empty?
            flash[:invalid_lines] = invalid_lines
            flash[:error] = I18n.t('csv_invalid_lines')
          end
          if nb_updates > 0
            flash[:upload_notice] = I18n.t('rubric_criteria.upload.success', :nb_updates => nb_updates)
          end
        end
      end
    end
    redirect_to :action => 'index', :id => @assignment.id
  end


  def yml_upload
    @assignment = Assignment.find(params[:id])
    if !request.post?
      redirect_to :action => 'index', :id => @assignment.id
      return
    end
    file = params[:yml_upload][:rubric]
    if !file.nil? && !file.blank?
      begin
        rubrics = YAML::load(file)
      rescue ArgumentError => e
        flash[:error] =
           I18n.t('rubric_criteria.upload.error') + "  " +
           I18n.t('rubric_criteria.upload.syntax_error', :error => "#{e}")
        redirect_to :action => 'index', :id => @assignment.id
        return
      end
      if not rubrics
        flash[:error] = I18n.t('rubric_criteria.upload.error') + 
          "  " + I18n.t('rubric_criteria.upload.empty_error')
        redirect_to :action => 'index', :id => @assignment.id
        return
      end
      successes = 0
      rubrics.each do |key|
        begin
          RubricCriterion.create_or_update_from_yml_key(key, @assignment)
          successes += 1
        rescue RuntimeError => e
          flash[:error] = I18n.t('rubric_criteria.upload.syntax_error', :error => "#{e}")
        end
      end

      if successes < rubrics.length

        flash[:error] = I18n.t('rubric_criteria.upload.error') + "  " + flash[:error]

      end

      if successes > 0

        flash[:upload_notice] = I18n.t('rubric_criteria.upload.success', :nb_updates => successes)

      end
    end

    redirect_to :action => 'index', :id => @assignment.id

  end


  #This method handles the drag/drop RubricCriteria sorting
  def update_positions
    unless request.post?
      render :nothing => true
      return
    end
    @assignment = Assignment.find(params[:aid])
    @criteria = @assignment.rubric_criteria
    params[:rubric_criteria_pane_list].each_with_index do |id, position|
      if id != ""
        RubricCriterion.update(id, :position => position+1)
      end
    end
  end

  def move_criterion
    position = params[:position].to_i
    unless request.post?
      render :nothing => true
      return
    end
    if params[:direction] == 'up'
      offset = -1
    elsif  params[:direction] == 'down'
      offset = 1
    else
      render :nothing => true
      return
    end
    @assignment = Assignment.find(params[:aid])
    @criteria = @assignment.rubric_criteria
    criterion = @criteria.find(params[:id])
    index = @criteria.index(criterion)
    other_criterion = @criteria[index + offset]
    if other_criterion.nil?
      render :nothing => true
      return
    end
    RubricCriterion.update(criterion.id, :position => other_criterion.position)
    RubricCriterion.update(other_criterion.id, :position => position)
    @criteria.reload
  end
  
end
