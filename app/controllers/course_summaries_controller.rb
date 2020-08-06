class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  before_action :authorize_only_for_admin,
                except: [:populate, :index]

  layout 'assignment_content'

  def index
  end

  def populate
    visible_assessments_info = {}
    marking_schemes = {}
    if current_user.admin?
      visible_assessments = Assessment.all.order(id: :asc)
      MarkingScheme.all.each do |m|
        grades = m.students_weighted_grades_array(current_user)
        marking_schemes[m.name] = { average: DescriptiveStatistics.mean(grades).round(2),
                                    median: DescriptiveStatistics.median(grades).round(2) }
      end
    else
      visible_assessments = Assessment.where(is_hidden: false).order(id: :asc)
    end
    visible_assessments.each do |a|
      visible_assessments_info[a.short_identifier] = assessment_overview(a)
    end
    render json: {
      assessment_info: visible_assessments_info,
      columns: populate_columns,
      data: get_table_json_data(current_user),
      schemes: marking_schemes
    }
  end

  def view_summary
    @marking_schemes = MarkingScheme.all
    @marking_weights = MarkingWeight.all
    @assessments = Assessment.all
  end

  def get_marking_scheme_details
    redirect_to url_for(controller: 'marking_schemes', action: 'populate')
  end

  def download_csv_grades_report
    assessments = Assessment.all.order(id: :asc).pluck(:id)
    marking_schemes = MarkingScheme.all.pluck(:id)
    grades_data = get_table_json_data(current_user)

    csv_string = MarkusCsv.generate(grades_data, [generate_csv_header]) do |student|
      row = [student[:user_name], student[:first_name], student[:last_name], student[:id_number]]
      row.concat(assessments.map { |a_id| student[:assessment_marks][a_id]&.[](:mark) || nil })
      row.concat(marking_schemes.map { |ms_id| student[:weighted_marks][ms_id] })
      row
    end
    name_grades_report_file(csv_string)
  end

  private

  def generate_csv_header
    assessments = Assessment.all.order(id: :asc)
    marking_schemes = MarkingScheme.all

    header = [User.human_attribute_name(:user_name),
              User.human_attribute_name(:first_name),
              User.human_attribute_name(:last_name),
              User.human_attribute_name(:id_number)]
    header.concat(assessments.map(&:short_identifier))
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
      assessments = Assessment.order(id: :asc).pluck(:id, :short_identifier)
      marking_schemes = MarkingScheme.pluck(:id, :name)
    else
      assessments = Assessment.where(is_hidden: false).order(id: :asc).pluck(:id, :short_identifier)
      marking_schemes = MarkingScheme.none
    end

    assessment_columns = assessments.map do |id, short_identifier|
      {
        accessor: "assessment_marks.#{id}.mark",
        Header: short_identifier,
        minWidth: 50,
        className: 'number',
        headerStyle: { textAlign: 'right' }
      }
    end

    marking_scheme_columns = marking_schemes.map do |id, name|
      {
        accessor: "weighted_marks.#{id}",
        Header: name,
        minWidth: 50,
        className: 'number',
        headerStyle: { textAlign: 'right' }
      }
    end

    assessment_columns.concat(marking_scheme_columns)
  end

  def assessment_overview(assessment)
    if assessment.is_a? GradeEntryForm
      info = { total: assessment.grade_entry_items.sum(:out_of), average: assessment.calculate_average&.round(2) }
      if current_user.admin?
        info[:median] = assessment.calculate_median&.round(2)
      end
    else
      info = { total: assessment.max_mark, average: assessment.results_average&.round(2) }
      if current_user.admin? || assessment.display_median_to_students
        info[:median] = assessment.results_median&.round(2)
      end
    end
    info
  end
end
