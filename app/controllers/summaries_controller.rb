class SummariesController < ApplicationController
  include SummariesHelper

  def index
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.marking_scheme_type == 'rubric'
      @criteria = @assignment.rubric_criteria
    else
      @criteria = @assignment.flexible_criteria
    end
    respond_to do |format|
      format.html
      format.json { render json: get_summaries_table_info(@assignment) }
    end
  end
end
