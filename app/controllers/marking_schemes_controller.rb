class MarkingSchemesController < ApplicationController
  include MarkingSchemesHelper
  
  def index
    @assignments = Assignment.all
  end
  
  def populate
    render json: get_table_json_data
  end

  def create
    puts params
    redirect_to action: 'index'
  end
  
  def new
    @marking_scheme = MarkingScheme.new
    @all_assignments = Assignment.all
    @all_assignments.count.times do
      marking_weight = @marking_scheme.marking_weights.build  
    end
  end

  def edit
  end
end
