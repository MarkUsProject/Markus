class MarkingSchemesController < ApplicationController
  include MarkingSchemesHelper

  respond_to :html, :js
  before_action :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignments = Assignment.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def populate
    table = get_table_json_data
    assignment_weights = []
    spreadsheet_weights = []

    assignment_names = Assignment.pluck(:id, :short_identifier)

    spreadsheet_names = GradeEntryForm.pluck(:id, :short_identifier)

    assignment_weights.concat(assignment_names.map do |id, sh_identifier|
      {
        accessor: "assignment_weights.#{id}",
        Header: sh_identifier
      }
    end)

    spreadsheet_weights.concat(spreadsheet_names.map do |id, sh_identifier|
      {
        accessor: "spreadsheet_weights.#{id}",
        Header: sh_identifier
      }
    end)
    render json: { data: table, marks: assignment_weights.concat(spreadsheet_weights) }
  end

  def create
    ApplicationRecord.transaction do
      begin
        # save marking scheme
        marking_scheme =
          MarkingScheme.new(name: params['marking_scheme']['name'])
        marking_scheme.save!

        # save marking weights
        params['marking_scheme']['marking_weights_attributes'].each \
          do |_key, obj|
          is_assignment = (obj['type'] == 'Assignment')

          marking_weight = MarkingWeight.new(
            gradable_item_id: obj['id'],
            is_assignment: is_assignment,
            marking_scheme_id: marking_scheme.id,
            weight: obj['weight'])

          marking_weight.save!
        end
      rescue ActiveRecord::RecordInvalid => invalid
        # Rollback
      end
    end

    redirect_to marking_schemes_path
  end

  def update
    ApplicationRecord.transaction do
      begin
        # save marking scheme
        marking_scheme = MarkingScheme.find(params['id'])
        marking_scheme.name = params['marking_scheme']['name']
        marking_scheme.save!

        # save marking weights
        params['marking_scheme']['marking_weights_attributes'].each \
          do |_key, obj|
          is_assignment = (obj['type'] == 'Assignment')

          marking_weight = MarkingWeight.where(
            gradable_item_id: obj['id'],
            is_assignment: is_assignment,
            marking_scheme_id: marking_scheme.id).first

          marking_weight.weight = obj['weight']
          marking_weight.save!
        end
      rescue ActiveRecord::RecordInvalid => invalid
        # Rollback
      end
    end

    redirect_to marking_schemes_path
  end

  def new
    @marking_scheme = MarkingScheme.new
    @assignments = Assignment.all
    @grade_entry_forms = GradeEntryForm.all

    @all_gradable_items = @assignments + @grade_entry_forms
    @all_gradable_items.count.times do
      @marking_scheme.marking_weights.build
    end
  end

  def edit
    @marking_scheme = MarkingScheme.find(params['id'])

    @all_gradable_items = []

    MarkingWeight.where(marking_scheme_id: @marking_scheme.id).each do |mw|
      if mw.is_assignment
        @all_gradable_items << Assignment.find(mw.gradable_item_id)
      else
        @all_gradable_items << GradeEntryForm.find(mw.gradable_item_id)
      end
    end
  end

  def destroy
    MarkingScheme.find(params['id']).destroy
    @assignments = Assignment.all
    @grade_entry_forms = GradeEntryForm.all
    render :index
  end
end
