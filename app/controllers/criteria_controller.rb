class CriteriaController < ApplicationController

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @criterion_type = params[:criterion_type]
    @criterion = get_class(@criterion_type).new
  end

  def edit
    @criterion_type = params[:criterion_type]
    @criterion = get_class(@criterion_type).find(params[:id])
  end

  # This method handles the drag/drop criteria sorting
  def update_positions
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.get_criteria
    position = 0

    params[:criterion].each do |id|
      if id != ''
        position += 1
        @assignment.criterion_class.update(id, position: position)
      end
    end
  end

  # Returns the class of the criterion.
  def get_class(criterion_type)
    if criterion_type == 'flexible'
      FlexibleCriterion
    elsif criterion_type == 'rubric'
      RubricCriterion
    end
  end

end
