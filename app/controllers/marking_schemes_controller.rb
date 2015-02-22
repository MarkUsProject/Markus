class MarkingSchemesController < ApplicationController
  include MarkingSchemesHelper
  
  def index
    @assignments = Assignment.all
  end
  
  def populate
    render json: get_table_json_data
  end

  def create
    marking_scheme_name = params["marking_scheme"]
    assignment_weights = []
    all_assignments = Assignment.all
    all_assignments.each_with_index do |assignment, index|
      assignment_weights << params["marking_scheme"]["marking_weights_attributes"][index.to_s]["weight"]
    end

    ActiveRecord::Base.transaction do
      begin
        marking_scheme = MarkingScheme.new(marking_scheme_name)
        if (marking_scheme.save)
          assignment_weights.each_with_index do |a_weight, index|
            marking_weight = MarkingWeight.new("a_id"=>all_assignments[index].id, "marking_scheme_id"=>marking_scheme.id, "weight"=>assignment_weights[index])
            marking_weight.save
          end
        end
      # TODO: Handle error
      end
    end

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
