class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  before_action :authorize_only_for_admin,
                except: [:populate]

  layout 'assignment_content'

  def index
  end

  def populate
    render json: {
      data: get_table_json_data(current_user),
      columns: populate_columns
    }
  end

  def view_summary
    @assignments = Assignment.all
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def get_marking_scheme_details
    redirect_to url_for(controller: 'marking_schemes', action: 'populate')
  end

  def download_csv_grades_report
    assignments = Assignment.all.pluck(:id)
    grade_entry_forms = GradeEntryForm.all.pluck(:id)
    marking_schemes = MarkingScheme.all.pluck(:id)
    grades_data = get_table_json_data(current_user)

    csv_string = MarkusCsv.generate(grades_data, [generate_csv_header]) do |student|
      row = [student[:user_name], student[:first_name], student[:last_name], student[:id_number]]
      row.concat(assignments.map { |a_id| student[:assignment_marks][a_id] || nil })
      row.concat(grade_entry_forms.map { |gef_id| student[:grade_entry_form_marks][gef_id] || nil })
      row.concat(marking_schemes.map { |ms_id| student[:weighted_marks][ms_id] })
      row
    end
    name_grades_report_file(csv_string)
  end

  private

  def generate_csv_header
    assignments = Assignment.all
    grade_entry_forms = GradeEntryForm.all
    marking_schemes = MarkingScheme.all

    header = [User.human_attribute_name(:user_name),
              User.human_attribute_name(:first_name),
              User.human_attribute_name(:last_name),
              User.human_attribute_name(:id_number)]
    header.concat(assignments.map(&:short_identifier))
    header.concat(grade_entry_forms.map(&:short_identifier))
    header.concat(marking_schemes.map(&:name))

    header
  end

  def name_grades_report_file(csv_string)
    course_name = Rails.configuration.course_name.squish.downcase.tr(' ', '_')
    send_data csv_string,
              disposition: 'attachment',
              filename: "#{course_name}_grades_report.csv"
  end

  def populate_columns
    if current_user.admin? || current_user.ta?
      assignments = Assignment.pluck(:id, :short_identifier)
      gefs = GradeEntryForm.pluck(:id, :short_identifier)
      marking_schemes = MarkingScheme.pluck(:id, :name)
    else
      assignments = Assignment.where(is_hidden: false).pluck(:id, :short_identifier)
      gefs = GradeEntryForm.where(is_hidden: false).pluck(:id, :short_identifier)
      marking_schemes = MarkingScheme.none
    end

    assignment_columns = assignments.map do |id, short_identifier|
      {
        accessor: "assignment_marks.#{id}",
        Header: short_identifier,
        minWidth: 50,
        className: 'number'
      }
    end

    gef_columns = gefs.map do |id, short_identifier|
      {
        accessor: "grade_entry_form_marks.#{id}",
        Header: short_identifier,
        minWidth: 50,
        className: 'number'
      }
    end

    marking_scheme_columns = marking_schemes.map do |id, name|
      {
        accessor: "weighted_marks.#{id}",
        Header: name,
        minWidth: 50,
        className: 'number'
      }
    end

    assignment_columns.concat(gef_columns, marking_scheme_columns)
  end
end
