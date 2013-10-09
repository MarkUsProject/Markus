class FlexibleCriteriaController < ApplicationController

  before_filter      :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.past_due_date?
      flash[:notice] = t('past_due_date_warning')
    end
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
    unless @criterion.update_attributes(params[:flexible_criterion])
      render :errors
      return
    end
    flash.now[:success] = I18n.t('criterion_saved_success')
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @criterion = FlexibleCriterion.new
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
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
    unless @criterion.update_attributes(params[:flexible_criterion])
      @errors = @criterion.errors
      render :add_criterion_error
      return
    end
    @criteria.reload
    render :create_and_edit
  end

  def destroy
    @criterion = FlexibleCriterion.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.flexible_criteria
    # TODO delete all marks associated with this criterion
    # Will be possible when Mark gets its association with FlexibleCriterion.
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
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
            flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
          end
          if nb_updates > 0
            flash[:notice] = I18n.t('flexible_criteria.upload.success',
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
      unless id == ''
        FlexibleCriterion.update(id, :position => position + 1)
      end
    end
  end

  #This method handles the arrows
  def move_criterion
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
    # Increase the index by one as the position value is 1 greater than the index
    index = index + 1
    criterion.position = index + offset
    other_criterion.position = index
    unless criterion.save and other_criterion.save
      flash[:error] = I18n.t('flexible_criteria.move_criterion.error')
    end
    @criteria.reload
  end

end
