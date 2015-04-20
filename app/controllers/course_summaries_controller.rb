class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  def index
    @assignments       = Assignment.all
    @marking_schemes   = MarkingScheme.all
    @marking_weights   = MarkingWeight.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def populate
    render json: get_table_json_data
  end

  def get_max_marks_for_assignments
    render json: get_max_mark_for_assignments
  end
  
  def get_max_marks_for_grade_entry_forms
    render json: get_max_mark_for_grade_entry_forms
  end

  def get_marking_weights_for_marking_schemes
    render json: get_marking_weights_for_all_marking_schemes
  end

  def get_marking_scheme_details
    # render json: Class.new.extend(MarkingSchemesHelper).get_table_json_data
    redirect_to url_for(controller: "marking_schemes", action: "populate")
  end
end
