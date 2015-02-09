class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  def index
    @assignments = Assignment.all();
  end

  def populate
    render json: get_table_json_data()
  end
end
