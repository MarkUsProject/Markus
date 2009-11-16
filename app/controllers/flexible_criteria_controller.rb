class FlexibleCriteriaController < ApplicationController
  
  before_filter      :authorize_only_for_admin
  
  def index
    @assignment = Assignment.find(params[:id])
    # TODO until Assignment gets its criteria method
    @criteria = FlexibleCriterion.find_all_by_assignment_id(@assignment.id, :order => :position)
  end
  
  def edit 
    @criterion = FlexibleCriterion.find(params[:id])
  end
  
  def update
    @criterion = FlexibleCriterion.find(params[:id])
    if !@criterion.update_attributes(params[:flexible_criterion])
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
      @criterion = FlexibleCriterion.new
      @criterion.assignment = @assignment
      @criterion.max = FlexibleCriterion::DEFAULT_MAX
      @criterion.position = FlexibleCriterion.next_criterion_position(@assignment)
      if !@criterion.update_attributes(params[:flexible_criterion])
        @errors = @criterion.errors
        render :action => 'add_criterion_error'
        return
      end
      render :action => 'create_and_edit'
    end
  end
  
  def delete
    return unless request.delete?
    @criterion = FlexibleCriterion.find(params[:id])
    # TODO delete all marks associated with this criterion
    #      Will be possible when Mark gets its association with FlexibleCriterion.
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
  end
  
  def download
    @assignment = Assignment.find(params[:id])
    file_out = FlexibleCriterion.create_csv(@assignment)
    send_data(file_out, :type => 'text/csv', :filename => "#{@assignment.short_identifier}_flexible_criteria.csv", :disposition => 'inline')
  end
  
  def upload
    file = params[:upload][:flexible]
    @assignment = Assignment.find(params[:id])
    if request.post? && !file.blank?
      begin
        FlexibleCriterion.transaction do
          invalid_lines = []
          nb_updates = FlexibleCriterion.parse_csv(file, @assignment, invalid_lines)
          unless invalid_lines.empty? 
            flash[:invalid_lines] = invalid_lines
            flash[:error] = I18n.t('csv_invalid_lines')
          end
          if nb_updates > 0
            flash[:upload_notice] = I18n.t('flexible_criteria.upload.success', :nb_updates => nb_updates)
          end
        end
      end
    end
    redirect_to :action => 'index', :id => @assignment.id
  end
  
  # This method handles the drag/drop criteria sorting
  def update_positions
    unless request.post?
      render :nothing => true
      return
    end
    params[:flexible_criteria_pane_list].each_with_index do |id, position|
      if id != ""
        FlexibleCriterion.update(id, :position => position + 1)
      end
    end
    render :nothing => true
  end

end