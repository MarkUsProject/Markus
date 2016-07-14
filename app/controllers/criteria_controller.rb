class CriteriaController < ApplicationController

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @criterion_type = params[:criterion_type]
    @criterion = @criterion_type.constantize.new
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @criterion_type = params[:criterion_type]
    @criteria = @assignment.get_criteria
    @criterion = @criterion_type.constantize.new
    @criterion.assignment = @assignment
    @criterion.max_mark = @criterion_type.constantize::DEFAULT_MAX_MARK
    @criterion.position = @assignment.next_criterion_position
    rubric = @criterion_type == 'RubricCriterion'
    @criterion.set_default_levels if rubric
    unless rubric ?
      @criterion.update(rubric_criterion_params.deep_merge(params.require(:rubric_criterion).permit(:max_mark)))
      : @criterion.update(flexible_criterion_params)
      @errors = @criterion.errors
      render 'add_criterion_error', formats: [:js], handlers: [:erb]
      return
    end
    @criteria.reload
    render 'create_and_edit', formats: [:js], handlers: [:erb]
  end

  def edit
    @criterion_type = params[:criterion_type]
    @criterion = @criterion_type.constantize.find(params[:id])
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
