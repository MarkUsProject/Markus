class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  def index
    @assignments = Assignment.all
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
  end

  def populate
    render json: get_table_json_data
  end

  def get_weight
    ms_id = params["ms_id"]
    weights = MarkingWeight.where(marking_scheme_id: ms_id)

    max_marks = get_max_mark_for_assignments

    render json: { weights: weights, max_marks: max_marks }.to_json
  end
end
