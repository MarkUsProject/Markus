class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  before_filter :authorize_only_for_admin,
                except: [:populate]

  layout 'assignment_content'

  def index
    @assignments = Assignment.all
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def populate
    if current_user.admin?
      render json: get_table_json_data
    else
      render json: get_student_row_information
    end
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
    assignments = Assignment.order(:id)
    grade_entry_forms = GradeEntryForm.order(:id)
    marking_schemes = MarkingScheme.order(:id)

    header = ['Username']
    header.concat(assignments.map(&:short_identifier))
    header.concat(grade_entry_forms.map(&:short_identifier))
    header.concat(marking_schemes.map(&:name))

    csv << header
  end

  def insert_student_marks(csv)
    JSON.parse(get_table_json_data).each do |student|
      row = []
      row.push(student['user_name'])
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
