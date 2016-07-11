class CriteriaController < ApplicationController

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @criterion_type = params[:criterion_type]
    @criterion = @criterion_type.constantize.new
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

end
