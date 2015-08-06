class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  def index
    @assignments = Assignment.all
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
    @grade_entry_forms = GradeEntryForm.all
  end

  def populate
    render json: get_table_json_data
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
    assignments.each do |assignment|
      header.push(assignment.short_identifier)
    end
    grade_entry_forms.each do |grade_entry_form|
      header.push(grade_entry_form.short_identifier)
    end
    marking_schemes.each do |marking_scheme|
      header.push(marking_scheme.name)
    end
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
    send_data csv_string, disposition: 'attachment',
              filename: "#{course_name_underscore}_grades_report.csv"
  end
end
