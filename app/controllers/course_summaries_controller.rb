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
      # Populates the entire CSV with headers, students and their marks
      populate_students_and_marks(csv)
    end
    course_name = "#{COURSE_NAME}"
    course_name_underscore = course_name.squish.downcase.tr(' ', '_')
    send_data csv_string, disposition: 'attachment',
                          filename: "#{course_name_underscore}_grades_report.csv"
  end
end

# ---- HELPER FUNCTIONS FOR DOWNLOAD_CSV_GRADES_REPORT BELOW-----#

# Populates the headers in the CSV
def populate_header_titles(assignments)
  header = ['Username']
  assignments.each do |assignment|
    header.push(assignment.short_identifier)
  end
  header.push('Total marks')
end

# Checks grouping, submission and it's mark for nil.
def fill_row_with_marks(grouping, row)
  if check_for_nil_fields(grouping)
    row.push('')
  else
    row.push(grouping.current_submission_used.get_latest_result.total_mark /
                                       grouping.assignment.total_mark * 100)
  end
  row
end

# Loads up the CSV with headers, students and marks.
def populate_students_and_marks(csv)
  students = Student.all
  # Populates the csv header titles here
  csv << populate_header_titles(Assignment.order(:id))
  students.each do |student|
    total_mark = 0
    row = []
    row.push(student.user_name)
    Assignment.order(:id).each do |assignment|
      grouping = student.accepted_grouping_for(assignment.id)
      # Check for nil fields. If not nil, then fill up the rows!
      row = fill_row_with_marks(grouping, row)
      total_mark += get_total_marks_for_student(grouping)
    end
    row.push(total_mark)
    csv << row
  end
  csv
end

# Return the total marks for that student with its appropriate weights
def get_total_marks_for_student(grouping)
  current_total_marks = 0
  if not check_for_nil_fields(grouping)
    # Create Hashmap with Criteria ID as keys and it's weight as values
    criteria_id_to_weight = return_criteria_to_weight_for_grouping(grouping)
    get_assignment_marks(grouping).each do |mark|
      current_total_marks += mark.mark *
                              criteria_id_to_weight[mark.markable_id].to_f
    end
  end
  current_total_marks
end

# Function that is called to check for nill grouping, submissions and marks
def check_for_nil_fields(grouping)
  if grouping.nil? || grouping.current_submission_used.nil? ||
    (grouping.current_submission_used.get_latest_result.total_mark /
                          grouping.assignment.total_mark * 100).nan?
    return true
  else
    return false
  end
end

# Returns the appropriate criteria for a group assignment
def return_criteria_to_weight_for_grouping(grouping)
  criteria_id_to_weight = {}
  if grouping.assignment.marking_scheme_type == 'rubric'
    criteria_id_to_weight = map_criteria_id_to_weight('rubric',
                                                      grouping.assignment.rubric_criteria)
  elsif grouping.assignment.marking_scheme_type == 'flexible'
    criteria_id_to_weight = map_criteria_id_to_weight('flexible',
                                                      grouping.assignment.flexible_criteria)
  end
  criteria_id_to_weight
end

# Returns the marks that the group got on the assignment
def get_assignment_marks(grouping)
  grouping.current_submission_used.results.first.marks
end

# Load a hashmap with the criteria id to its weight according to its criterion
def map_criteria_id_to_weight(type, criterias)
  criteria_id_to_weight = {}
  if type == 'rubric'
    criterias.each do |criteria|
      criteria_id_to_weight[criteria.id] = criteria.weight
    end
  elsif type == 'flexible'
    criterias.each do |criteria|
      criteria_id_to_weight[criteria.id] = criteria.max.to_s('F')
    end
  end
  criteria_id_to_weight
end
