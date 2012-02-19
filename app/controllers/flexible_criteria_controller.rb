class FlexibleCriteriaController < ApplicationController

  before_filter      :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    # TODO until Assignment gets its criteria method
    @criteria =
      FlexibleCriterion.find_all_by_assignment_id( @assignment.id,
                                                   :order => :position)
  end

  def edit
    @criterion = FlexibleCriterion.find(params[:id])
  end

  def update
    @criterion = FlexibleCriterion.find(params[:id])
    if !@criterion.update_attributes(params[:flexible_criterion])
      render :errors
      return
    end
    flash.now[:success] = I18n.t('criterion_saved_success')
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    if !request.post?
      return
    else
      @criteria = @assignment.flexible_criteria
      if @criteria.length > 0
        new_position = @criteria.last.position + 1
      else
        new_position = 1
      end
      @criterion = FlexibleCriterion.new
      @criterion.assignment = @assignment
      @criterion.max = FlexibleCriterion::DEFAULT_MAX
      @criterion.position = new_position
      if !@criterion.update_attributes(params[:flexible_criterion])
        @errors = @criterion.errors
        render :add_criterion_error
        return
      end
      @criteria.reload
      render :create_and_edit
    end
  end

  def destroy
    return unless request.delete?
    @criterion = FlexibleCriterion.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.flexible_criteria
    # TODO delete all marks associated with this criterion
    # Will be possible when Mark gets its association with FlexibleCriterion.
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
    redirect_to :action => 'index', :id => @assignment
  end

  def download
    @assignment = Assignment.find(params[:assignment_id])
    file_out = FlexibleCriterion.create_csv(@assignment)
    send_data(file_out,
              :type => 'text/csv',
              :filename => "#{@assignment.short_identifier}_flexible_criteria.csv",
              :disposition => 'inline')
  end

  def upload
    file = params[:upload][:flexible]
    @assignment = Assignment.find(params[:assignment_id])
    if request.post? && !file.blank?
      begin
        FlexibleCriterion.transaction do
          invalid_lines = []
          nb_updates = FlexibleCriterion.parse_csv(file,
                                                   @assignment,
                                                   invalid_lines)
          unless invalid_lines.empty?
            flash[:invalid_lines] = invalid_lines
            flash[:error] = I18n.t('csv_invalid_lines')
          end
          if nb_updates > 0
            flash[:upload_notice] = I18n.t('flexible_criteria.upload.success',
                                            :nb_updates => nb_updates)
          end
        end
      end
    end
    redirect_to :action => 'index', :assignment_id => @assignment.id
  end

  # This method handles the drag/drop criteria sorting
  def update_positions
    unless request.post?
      render :nothing => true
      return
    end
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.flexible_criteria
    params[:flexible_criteria_pane_list].each_with_index do |id, position|
      if id != ""
        FlexibleCriterion.update(id, :position => position + 1)
      end
    end
  end

  #This method handles the arrows
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
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.flexible_criteria
    criterion = @criteria.find(params[:id])
    index = @criteria.index(criterion)
    other_criterion = @criteria[index + offset]
    if other_criterion.nil?
      render :nothing => true
      return
    end
    FlexibleCriterion.update(criterion.id,
                             :position => other_criterion.position)
    FlexibleCriterion.update(other_criterion.id, :position => position)
    @criteria.reload
  end

end
