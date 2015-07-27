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
    students = Student.all
    csv_string = CSV.generate do |csv|
      header = ['Username']
      assignments.each do |assignment|
        header.push(assignment.short_identifier)
      end
      header.push("Total marks")
      csv << header
      students.each do |student|
        row = []
        row.push(student.user_name)
        total_spreadsheet_mark = 0
        assignments.each do |assignment|
          out_of = assignment.total_mark
          grouping = student.accepted_grouping_for(assignment.id)
          if grouping.nil?
            row.push('')
          else
            submission = grouping.current_submission_used
            if submission.nil?
              row.push('')
            else
              total_mark_percentage = submission.get_latest_result.total_mark / out_of * 100
              if total_mark_percentage.nan?
                row.push('')
              else
                row.push(total_mark_percentage)
                total_spreadsheet_mark += total_mark_percentage
              end
            end
          end
        end
        row.push(total_spreadsheet_mark)
        csv << row
      end
    end
    course_name = "#{COURSE_NAME}"
    course_name_underscore = course_name.squish.downcase.tr(" ", "_")
    send_data csv_string, disposition: 'attachment',
              filename: "#{course_name_underscore}_grades_report.csv"
  end
end
