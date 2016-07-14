class CriteriaController < ApplicationController

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @criterion_type = params[:criterion_type]
    @criterion = @criterion_type.constantize.new
  end

  def edit
    @criterion_type = params[:criterion_type]
    @criterion = @criterion_type.constantize.find(params[:id])
  end

  def destroy
    @criterion = params[:criterion_type].constantize.find(params[:id])
    @assignment = @criterion.assignment
    @criteria = @assignment.get_criteria
    # Delete all marks associated with this criterion
    @criterion.destroy
    flash[:success] = I18n.t('criterion_deleted_success')
  end

  # This method handles the drag/drop criteria sorting.
  def update_positions
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.get_criteria

    ActiveRecord::Base.transaction do
      params[:criterion].
        each_with_index { |id, index| @assignment.criterion_class.update(id, position: index + 1) if id != '' }
    end
  end
end
