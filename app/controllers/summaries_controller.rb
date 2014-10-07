class SummariesController < ApplicationController
  include SummariesHelper

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @criteria = @assignment.rubric_criteria
    respond_to do |format|
      format.html
      format.json { render json: get_summaries_table_info(@assignment) }
    end
  end
end
