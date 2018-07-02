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
    if current_user.admin?
      table = JSON.parse(get_table_json_data)
      marks = table[0]['assignment_marks'].map do |marks|
          {
            accessor: "assignment_marks.#{marks[0]}",
            Header: Assignment.find(marks[0]).short_identifier
          }
      end
      gefm = table[0]['grade_entry_form_marks'].map do |marks|
        {
          accessor: "grade_entry_form_marks.#{marks[0]}",
          Header: GradeEntryForm.find(marks[0]).short_identifier
        }
      end
      markscheme = table[0]['weighted_marks'].map do |marks|
        {
          accessor: "weighted_marks.#{marks[0]}",
          Header: MarkingScheme.find(marks[0]).name
        }
      end
      render json: { data: get_table_json_data, marks: marks, grade_entry_forms: gefm, scheme: markscheme }
    else
      render json: get_student_row_information
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
    JSON.parse(get_table_json_data).each do |student|
      row = []
      row.push(student['user_name'])
      row.push(student['id_number'])
      row.concat(student['assignment_marks'].values)
      row.concat(student['grade_entry_form_marks'].values)
      row.concat(student['weighted_marks'].values)
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
