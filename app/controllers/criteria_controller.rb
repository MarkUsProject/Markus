class CriteriaController < ApplicationController

  # This method handles the drag/drop criteria sorting
  def update_positions
    unless request.post?
      render nothing: true
      return
    end

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
