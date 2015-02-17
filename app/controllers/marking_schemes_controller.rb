class MarkingSchemesController < ApplicationController
  def index
    @assignments = Assignment.all
  end
  
  def populate
    render json: get_table_json_data
  end
  
  def new
  end

  def edit
  end
end
