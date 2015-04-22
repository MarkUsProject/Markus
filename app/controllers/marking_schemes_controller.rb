class MarkingSchemesController < ApplicationController
  include MarkingSchemesHelper

  respond_to :html, :js

  def index
    @assignments = Assignment.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def populate
    render json: get_table_json_data
  end

  def create
    ActiveRecord::Base.transaction do
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
    ActiveRecord::Base.transaction do
      begin
        # save marking scheme
        marking_scheme = MarkingScheme.where(id: params['id'])[0]
        marking_scheme.name = params['marking_scheme']['name']
        marking_scheme.save!

        # save marking weights
        params['marking_scheme']['marking_weights_attributes'].each \
          do |_key, obj|
          is_assignment = (obj['type'] == 'Assignment')

          marking_weight = MarkingWeight.where(
            gradable_item_id: obj['id'],
            is_assignment: is_assignment,
            marking_scheme_id: marking_scheme.id)[0]

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
    @marking_scheme = MarkingScheme.where(id: params['id'])[0]

    @all_gradable_items = []

    MarkingWeight.where(marking_scheme_id: @marking_scheme.id).each do |mw|
      if mw.is_assignment
        @all_gradable_items << Assignment.where(id: mw.gradable_item_id)[0]
      else
        @all_gradable_items << GradeEntryForm.where(id: mw.gradable_item_id)[0]
      end
    end
  end

  def destroy
    MarkingScheme.find(params['id']).destroy
  end
end
