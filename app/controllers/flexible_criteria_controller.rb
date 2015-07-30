class FlexibleCriteriaController < ApplicationController

  before_filter      :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.past_all_due_dates?
      flash[:notice] = t('past_due_date_warning')
    end
    # TODO until Assignment gets its criteria method
    @criteria =
      FlexibleCriterion.where(assignment_id: @assignment.id).order(:position)
  end

  def edit
    @criterion = FlexibleCriterion.find(params[:id])
  end

  def update
    @criterion = FlexibleCriterion.find(params[:id])
    unless @criterion.update_attributes(flexible_criterion_params)
      @errors = @criterion.errors
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
    unless @criterion.update_attributes(flexible_criterion_params)
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
              type: 'text/csv',
              filename: "#{@assignment.short_identifier}_flexible_criteria.csv",
              disposition: 'inline')
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
              nb_updates: nb_updates)
          end
        end
      rescue CSV::MalformedCSVError
        flash[:error] = I18n.t('csv.upload.malformed_csv')
      end
    end
    redirect_to action: 'index', assignment_id: @assignment.id
  end

  # This method handles the drag/drop criteria sorting
  def update_positions
    unless request.post?
      render nothing: true
      return
    end

    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.flexible_criteria
    position = 0

    # if params[:criterion]
      params[:criterion].each do |id|
        if id != ''
          position += 1
          FlexibleCriterion.update(id, position: position)
        end
      end
    # end
  end

  private

  def flexible_criterion_params
    params.require(:flexible_criterion).permit(:flexible_criterion_name,
                                               :description,
                                               :position,
                                               :max)
  end
end
