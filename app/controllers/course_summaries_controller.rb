class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  def index
    @assignments = Assignment.all
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def populate
    render json: get_table_json_data
  end

  def get_marking_scheme_details
    redirect_to url_for(controller: 'marking_schemes', action: 'populate')
  end
end
