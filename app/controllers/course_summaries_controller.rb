class CourseSummariesController < ApplicationController
  include CourseSummariesHelper

  before_action :authorize_only_for_admin,
                except: [:populate, :index]

  layout 'assignment_content'

  def index
  end

  def populate
    data = get_table_json_data(current_user)
    columns = populate_columns
    average_data = columns.map { |h| [h[:Header], nil] }.to_h
    median_data = columns.map { |h| [h[:Header], nil] }.to_h
    individual_data = columns.map { |h| [h[:Header], nil] }.to_h
    labels = columns.each_with_index.map { |h, i| [h[:Header], i] }.to_h

    visible_assessments = Assessment.order(id: :asc)
    visible_assessments = visible_assessments.where(is_hidden: false) if current_user.student?

    visible_assessments.each do |a|
      info = assessment_overview(a)
      average_data[a.short_identifier] = info[:average]
      median_data[a.short_identifier] = info[:median]
      columns[labels[a.short_identifier]][:Header] += " / (#{info[:total].to_i})"
    end

    if current_user.admin?
      MarkingScheme.all.each do |m|
        grades = m.students_weighted_grades_array(current_user)
        average_data[m.name] = DescriptiveStatistics.mean(grades).round(2)
        median_data[m.name] = DescriptiveStatistics.median(grades).round(2)
      end
    else
      data.first[:assessment_marks].each do |id, mark_data|
        individual_data[Assessment.find_by_id(id).short_identifier] = mark_data[:percentage]
      end
    end

    render json: {
      columns: columns,
      data: data,
      labels: labels.keys,
      average_data: average_data.values,
      median_data: median_data.values,
      individual_data: individual_data.values
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
      info = { total: assessment.grade_entry_items.where(bonus: false).sum(:out_of),
               average: assessment.calculate_average&.round(2) }
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
