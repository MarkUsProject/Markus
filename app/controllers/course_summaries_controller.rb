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
    assignment_marks = []
    gefms = []

    assignment_names = Assignment.pluck(:id, :short_identifier)
    gefms_names = GradeEntryForm.pluck(:id, :short_identifier)

    if current_user.admin?
      table = get_table_json_data
      mark_schemes = []

      markscheme_names = MarkingScheme.pluck(:id, :name)

      assignment_marks.concat(assignment_names.map do |id, sh_identifier|
        {
          accessor: "assignment_marks.#{id}",
          Header: sh_identifier
        }
      end)

      gefms.concat(gefms_names.map do |id, sh_identifier|
        {
          accessor: "grade_entry_form_marks.#{id}",
          Header: sh_identifier
        }
      end)

      mark_schemes.concat(markscheme_names.map do |id, name|
        {
          accessor: "weighted_marks.#{id}",
          Header: name
        }
      end)

      render json: { data: table, marks: assignment_marks.concat(gefms).concat(mark_schemes) }

    else
      table = get_student_row_information

      assignment_marks.concat(assignment_names.map do |id, sh_identifier|
        {
          accessor: "assignment_marks.#{id}",
          Header: sh_identifier
        }
      end)

      gefms.concat(gefms_names.map do |id, sh_identifier|
        {
          accessor: "grade_entry_form_marks.#{id}",
          Header: sh_identifier
        }
      end)

      render json: { data: table, marks: assignment_marks.concat(gefms) }

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
