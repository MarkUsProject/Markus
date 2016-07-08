class FlexibleCriteriaController < ApplicationController

  before_filter      :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.past_all_due_dates?
      flash[:notice] = t('past_due_date_warning')
    end
    @criteria = @assignment.get_criteria.order(:position)
  end

  def update
    @criterion = FlexibleCriterion.find(params[:id])
    unless @criterion.update_attributes(flexible_criterion_params)
      @errors = @criterion.errors
      render 'criteria/errors', formats: [:js], handlers: [:erb]
      return
    end
    flash.now[:success] = I18n.t('criterion_saved_success')
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.get_criteria
    @criterion = FlexibleCriterion.new
    @criterion.assignment = @assignment
    @criterion.max_mark = FlexibleCriterion::DEFAULT_MAX_MARK
    @criterion.position = @assignment.next_criterion_position
    unless @criterion.update_attributes(flexible_criterion_params)
      @errors = @criterion.errors
      render 'criteria/add_criterion_error', formats: [:js], handlers: [:erb]
      return
    end
    @criteria.reload
    render 'criteria/create_and_edit', formats: [:js], handlers: [:erb]
  end

  def destroy
    @criterion = FlexibleCriterion.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.get_criteria
    # TODO delete all marks associated with this criterion
    # Will be possible when Mark gets its association with FlexibleCriterion.
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
    render 'criteria/destroy', formats: [:js], handlers: [:erb]
  end

  def download
    @assignment = Assignment.find(params[:assignment_id])
    criteria = @assignment.get_criteria.order(:position)
    file_out = MarkusCSV.generate(criteria) do |criterion|
      [criterion.name, criterion.max_mark, criterion.description]
    end
    send_data(file_out,
              type: 'text/csv',
              filename: "#{@assignment.short_identifier}_flexible_criteria.csv",
              disposition: 'inline')
  end

  def upload
    file = params[:upload][:flexible]
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if request.post? && !file.blank?
      FlexibleCriterion.transaction do
        result = MarkusCSV.parse(file.read, encoding: encoding) do |row|
          next if CSV.generate_line(row).strip.empty?
          FlexibleCriterion.create_or_update_from_csv_row(row, @assignment)
        end
        unless result[:invalid_lines].empty?
          flash_message(:error, result[:invalid_lines])
        end
        unless result[:valid_lines].empty?
          flash_message(:success, result[:valid_lines])
        end
      end
    end
    redirect_to action: 'index', assignment_id: @assignment.id
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
end
