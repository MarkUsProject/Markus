class CriteriaController < ApplicationController

  # This method handles the drag/drop criteria sorting.
  def update_positions
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.get_criteria
    position = 1

    ActiveRecord::Base.transaction do
      params[:criterion].
        each_with_index { |id, index| @assignment.criterion_class.update(id, position: position + index) if id != '' }
    end
  end
end
