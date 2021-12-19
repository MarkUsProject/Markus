class MarkingSchemesController < ApplicationController
  include MarkingSchemesHelper

  respond_to :html, :js
  before_action { authorize! }

  layout 'assignment_content'

  def index
    @assignments = current_course.assignments
    @grade_entry_forms = current_course.grade_entry_forms
  end

  def populate
    columns = current_course.assessments.order(:type, :id).pluck(:id, :short_identifier).map do |id, short_identifier|
      {
        accessor: "assessment_weights.#{id}",
        Header: short_identifier,
        minWidth: 50,
        className: 'number'
      }
    end

    render json: {
      data: get_table_json_data(current_course),
      columns: columns
    }
  end

  def create
    ApplicationRecord.transaction do
      begin
        # save marking scheme
        marking_scheme = current_course.marking_schemes.new(name: params['marking_scheme']['name'])
        marking_scheme.save!

        # save marking weights
        params['marking_scheme']['marking_weights_attributes']&.each do |_key, obj|

          marking_weight = MarkingWeight.new(
            assessment_id: obj['id'],
            marking_scheme_id: marking_scheme.id,
            weight: obj['weight'])

          marking_weight.save!
        end
      rescue ActiveRecord::RecordInvalid => invalid
        # Rollback
      end
    end

    redirect_to course_marking_schemes_path(current_course)
  end

  def update
    ApplicationRecord.transaction do
      begin
        # save marking scheme
        marking_scheme = record
        marking_scheme.name = params['marking_scheme']['name']
        marking_scheme.save!

        # save marking weights
        params['marking_scheme']['marking_weights_attributes']&.each do |_key, obj|

          marking_weight = MarkingWeight.where(
            assessment_id: obj['id'],
            marking_scheme_id: marking_scheme.id).first

          marking_weight.weight = obj['weight']
          marking_weight.save!
        end
      rescue ActiveRecord::RecordInvalid => invalid
        # Rollback
      end
    end

    redirect_to course_marking_schemes_path(current_course)
  end

  def new
    @marking_scheme = current_course.marking_schemes.new
    @assignments = current_course.assignments
    @grade_entry_forms = current_course.grade_entry_forms

    @all_gradable_items = @assignments + @grade_entry_forms
    @all_gradable_items.count.times do
      @marking_scheme.marking_weights.build
    end
  end

  def edit
    @marking_scheme = record

    @all_gradable_items = []

    MarkingWeight.where(marking_scheme_id: @marking_scheme.id).each do |mw|
      @all_gradable_items << mw.assessment
    end
  end

  def destroy
    record.destroy
    @assignments = current_course.assignments
    @grade_entry_forms = current_course.assignments
    render :index
  end
end
