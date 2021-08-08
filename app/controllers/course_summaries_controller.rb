class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  before_action { authorize! }

  layout 'assignment_content'

  def index
  end

  def populate
    table_data = get_table_json_data(current_user)
    assessments = current_user.student? ? Assessment.where(is_hidden: false) : Assessment
    marking_schemes = current_user.student? ? MarkingScheme.none : MarkingScheme

    average, median, individual, assessment_columns, marking_scheme_columns, graph_labels = [], [], [], [], [], []
    single = current_user.student? ? Hash[table_data.first[:assessment_marks].map { |k, v| [k, v[:percentage]] }] : {}

    assessments.order(id: :asc).each do |a|
      info = assessment_overview(a)
      graph_labels << a.short_identifier
      average << info[:average]
      median << info[:median]
      assessment_columns << { id: a.id, name: "#{a.short_identifier} (/#{info[:total].to_f.round(2)})" }
      individual << single[a.id]
    end
    marking_schemes.order(id: :asc).each do |m|
      grades = table_data.map { |s| s[:weighted_marks][m.id][:mark] }
      total = m.marking_weights.pluck(:weight).compact.sum
      graph_labels << m.name
      if total.zero?
        average << nil
        median << nil
      else
        average << (DescriptiveStatistics.mean(grades) * 100 / total).round(2).to_f
        median << (DescriptiveStatistics.median(grades) * 100 / total).round(2).to_f
      end
      marking_scheme_columns << { id: m.id, name: m.name }
    end
    render json: {
      data: table_data,
      graph_data: { average: average, median: median, individual: individual },
      graph_labels: graph_labels,
      assessments: assessment_columns,
      marking_schemes: marking_scheme_columns
    }
  end

  def grade_distribution
    marking_schemes = current_user.student? ? MarkingScheme.none : MarkingScheme
    table_data = marking_schemes.order(id: :asc).map { |m| m.students_grade_distribution(current_user) }
    grades = marking_schemes.order(id: :asc).map { |m| m.students_weighted_grades_array(current_user) }
    marking_schemes_id = marking_schemes.order(id: :asc).map(&:id)

    labels = (0..100).step(5).to_a

    average, median = [], [], []
    unless table_data.empty?
      grades.each do |grade|
        average << ActiveSupport::NumberHelper.number_to_percentage(
          DescriptiveStatistics.mean(grade) || 0, precision: 1
        )
        median << ActiveSupport::NumberHelper.number_to_percentage(
          DescriptiveStatistics.median(grade) || 0, precision: 1
        )
      end
    end
    summary = {
      average: average,
      median: median
    }

    render json: {
      datasets: table_data,
      labels: labels,
      marking_schemes_id: marking_schemes_id,
      summary: summary
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

    csv_string = MarkusCsv.generate(grades_data, [generate_csv_header, generate_out_of_row]) do |student|
      row = [student[:user_name], student[:first_name], student[:last_name], student[:id_number]]
      row.concat(assessments.map { |a_id| student[:assessment_marks][a_id]&.[](:mark) || nil })
      row.concat(marking_schemes.map { |ms_id| student[:weighted_marks][ms_id][:mark] })
      row
    end
    name_grades_report_file(csv_string)
  end

  private

  def generate_out_of_row
    # This function creates the second row of the grades summary, containing the max mark of every assessment.
    # Given that each assessment has a maximum possible mark achievable, this row represents this data.
    assessments = Assessment.all.order(id: :asc)
    marking_schemes = MarkingScheme.all.order(id: :asc)
    out_of_row = [Assessment.human_attribute_name(:max_mark), '', '', '']
    out_of_row.concat(assessments.collect(&:max_mark))
    out_of_row.concat([''] * marking_schemes.size)

    out_of_row
  end

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
    course_name = Settings.course_name.squish.downcase.tr(' ', '_')
    send_data csv_string,
              disposition: 'attachment',
              filename: "#{course_name}_grades_report.csv"
  end

  def get_assessment_data(assessment, type)
    case type
    when :median
      assessment.results_median&.round(2)
    when :average
      assessment.results_average&.round(2)
    when :total
      assessment.max_mark
    else
      nil
    end
  end

  def assessment_overview(assessment)
    data = {
      name: assessment.short_identifier,
      total: get_assessment_data(assessment, :total),
      average: nil,
      median: nil
    }
    if current_user.admin? || (current_user.student? && current_user.released_result_for?(assessment))
      data[:average] = get_assessment_data(assessment, :average)
      if current_user.admin? || assessment.display_median_to_students
        data[:median] = get_assessment_data(assessment, :median)
      end
    end
    data
  end

  protected

  def implicit_authorization_target
    OpenStruct.new policy_class: CourseSummaryPolicy
  end
end
