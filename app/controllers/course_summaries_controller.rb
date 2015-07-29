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
    assignments = Assignment.order(:id)
    csv_string = CSV.generate do |csv|
      #Populates the entire CSV with headers, students and their marks
      populated_csv = populate_students_and_marks(csv)
    end
    course_name = "#{COURSE_NAME}"
    course_name_underscore = course_name.squish.downcase.tr(" ", "_")
    send_data csv_string, disposition: 'attachment',
              filename: "#{course_name_underscore}_grades_report.csv"
  end
end

#---- HELPER FUNCTIONS FOR DOWNLOAD_CSV_GRADES_REPORT BELOW-----#

#Helper function for download_csv_grades_report. Populates the headers in the CSV
def populate_header_titles(assignments)
  header = ['Username']
  assignments.each do |assignment|
    header.push(assignment.short_identifier)
  end
  header.push("Total marks")
end

#Helper function for populate_students_and_marks. Checks grouping, submission and it's mark for nil.
def check_for_nil_fields(grouping, row, out_of)
  if grouping.nil? or grouping.current_submission_used.nil? or (grouping.current_submission_used.get_latest_result.total_mark / out_of * 100).nan?
    row.push('')
  else
    row.push(grouping.current_submission_used.get_latest_result.total_mark / out_of * 100)
  end
  return row
end

#Helper function for download_csv_grades_report. Loads up the CSV with headers, students and marks.
def populate_students_and_marks(csv)
  students = Student.all
  assignments = Assignment.order(:id)
  #Populates the csv header titles here
  csv << populate_header_titles(assignments)
  students.each do |student|
    row = []
    row.push(student.user_name)
      assignments.each do |assignment|
        grouping = student.accepted_grouping_for(assignment.id)
        #Cheeck for nil fields. If not nil, then fill up the rows!
        row = check_for_nil_fields(grouping, row, assignment.total_mark)
      end
    csv << row
  end
  return csv
end
