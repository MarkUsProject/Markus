class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  before_action :authorize_only_for_admin,
                except: [:populate]

  layout 'assignment_content'

  def index
    @assignments = Assignment.all
    @grade_entry_forms = GradeEntryForm.all
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
  end

  def populate
    if current_user.admin? || current_user.ta?
      assignment_columns = Assignment.pluck(:id, :short_identifier)
      gef_columns = GradeEntryForm.pluck(:id, :short_identifier)
    else
      assignment_columns = Assignment.where(is_hidden: false).pluck(:id, :short_identifier)
      gef_columns = GradeEntryForm.where(is_hidden: false).pluck(:id, :short_identifier)
    end

    assignment_columns = assignment_columns.map do |id, short_identifier|
      {
        accessor: "assignment_marks.#{id}",
        Header: short_identifier,
        minWidth: 50,
        className: 'number'
      }
    end

    gef_columns = gef_columns.map do |id, short_identifier|
      {
        accessor: "grade_entry_form_marks.#{id}",
        Header: short_identifier,
        minWidth: 50,
        className: 'number'
      }
    end

    if current_user.admin? || current_user.ta?
      marking_scheme_columns = MarkingScheme.pluck(:id, :name).map do |id, name|
        {
          accessor: "weighted_marks.#{id}",
          Header: name,
          minWidth: 50,
          className: 'number'
        }
      end

      render json: {
        data: get_table_json_data,
        columns: assignment_columns.concat(gef_columns).concat(marking_scheme_columns)
      }
    else
      render json: {
        data: get_student_row_information,
        columns: assignment_columns.concat(gef_columns)
      }
    end
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
    csv_string = CSV.generate do |csv|
      generate_csv_header(csv)
      insert_student_marks(csv)
    end
    name_grades_report_file(csv_string)
  end

  def generate_csv_header(csv)
    assignments = Assignment.all
    grade_entry_forms = GradeEntryForm.all
    marking_schemes = MarkingScheme.all

    header = [User.human_attribute_name(:user_name), User.human_attribute_name(:id_number)]
    header.concat(assignments.map(&:short_identifier))
    header.concat(grade_entry_forms.map(&:short_identifier))
    header.concat(marking_schemes.map(&:name))

    csv << header
  end

  def insert_student_marks(csv)
    get_table_json_data.each do |student|
      row = []
      row.push(student[:user_name])
      row.push(student[:id_number])
      row.concat(student[:assignment_marks].values)
      row.concat(student[:grade_entry_form_marks].values)
      row.concat(student[:weighted_marks].values)
      csv << row
    end
  end

  def name_grades_report_file(csv_string)
    course_name = "#{COURSE_NAME}"
    course_name_underscore = course_name.squish.downcase.tr(' ', '_')
    send_data csv_string,
              disposition: 'attachment',
              filename: "#{course_name_underscore}_grades_report.csv"
  end
end
