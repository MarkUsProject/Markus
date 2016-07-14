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

  def update
    @criterion_type = params[:criterion_type]
    @criterion = @criterion_type.constantize.find(params[:id])
    rubric = @criterion_type == 'RubricCriterion'
    unless rubric ? @criterion.update(rubric_criterion_params.deep_merge(params.require(:rubric_criterion)
                                                                           .permit(:max_mark)
                                                                           .transform_values { |x|  (x.to_f * 4).to_s }))
      : @criterion.update(flexible_criterion_params)
      @errors = @criterion.errors
      render :errors
      return
    end
    flash.now[:success] = t('criterion_saved_success')
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
                                             :peer_visible)
  end

end
