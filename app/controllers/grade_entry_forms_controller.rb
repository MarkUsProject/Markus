# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  include GradeEntryFormsHelper
  include RoutingHelper
  before_action { authorize! }
  layout 'assignment_content'

  responders :flash

  # Create a new grade entry form
  def new
    @grade_entry_form = current_course.grade_entry_forms.new
  end

  def create
    # Edit params before updating model
    new_params = update_grade_entry_form_params(params)

    @grade_entry_form = current_course.grade_entry_forms.create(new_params)
    respond_with(@grade_entry_form,
                 location: -> { edit_course_grade_entry_form_path(current_course, @grade_entry_form) })
  end

  # Edit the properties of a grade entry form
  def edit
    @grade_entry_form = record
  end

  def update
    @grade_entry_form = record
    # Process changes to input properties
    new_params = update_grade_entry_form_params(params)

    @grade_entry_form.update(new_params)
    respond_with(@grade_entry_form,
                 location: -> { edit_course_grade_entry_form_path current_course, @grade_entry_form })
    GradeEntryStudent.refresh_total_grades(@grade_entry_form.grade_entry_students.ids)
  end

  def summary
    @grade_entry_form = record
    respond_to do |format|
      format.html { render layout: 'assignment_content' }
    end
  end

  # View/modify the grades for this grade entry form
  def grades
    @grade_entry_form = record
  end

  def view_summary
    @grade_entry_form = record
  end

  # Update a grade in the table
  def update_grade
    grade_entry_form = record
    grade_entry_student =
      grade_entry_form.grade_entry_students.find(params[:student_id])
    grade =
      grade_entry_student.grades.find_or_create_by(grade_entry_item_id: params[:grade_entry_item_id])

    grade.update(grade: params[:updated_grade])
    grade_entry_student.save # Refresh total grade
    grade_entry_student.reload
    render plain: grade_entry_student.total_grade
  end

  # For students
  def student_interface
    @grade_entry_form = record
    unless allowed_to?(:see_hidden?)
      render 'shared/http_status',
             formats: [:html],
             locals: {
               code: '404',
               message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: :not_found,
             layout: false
      return
    end

    # Getting the student's marks for each grade entry item
    @grade_entry_student = @grade_entry_form.grade_entry_students.find_by(role_id: current_role.id)
    @columns = []
    @data = []
    @item_percentages = []
    @labels = []
    @grade_entry_form.grade_entry_items.each do |grade_entry_item|
      @columns << "#{grade_entry_item.name} (#{grade_entry_item.out_of})"
      @labels << grade_entry_item.name
      mark = @grade_entry_student.grades.find_by(grade_entry_item_id: grade_entry_item.id)
      if !mark.nil? && !mark.grade.nil?
        @data << mark.grade
        @item_percentages << ((mark.grade * 100) / grade_entry_item.out_of).round(2)
      else
        @data << t(:not_applicable)
        @item_percentages << nil
      end
    end

    # Get data for the total marks column
    if @grade_entry_form.show_total
      @columns << "#{GradeEntryForm.human_attribute_name(:total)} (#{@grade_entry_form.max_mark})"
      total = @grade_entry_student.total_grade
      if !total.nil?
        @data << total
      else
        @data << t(:not_applicable)
      end
    end
  end

  def get_mark_columns
    grade_entry_form = record
    data = grade_entry_form.grade_entry_items.map do |column|
      {
        accessor: column.id.to_s,
        Header: "#{column.name} (#{column.out_of})"
      }
    end
    render json: data
  end

  def populate_grades_table
    grade_entry_form = record
    student_pluck_attrs = [
      Arel.sql('grade_entry_students.id as _id'),
      :released_to_student,
      Arel.sql('users.user_name as user_name'),
      Arel.sql('users.first_name as first_name'),
      Arel.sql('users.last_name as last_name'),
      Arel.sql('roles.hidden as hidden'),
      Arel.sql('roles.section_id as section_id')
    ]
    if grade_entry_form.show_total
      student_pluck_attrs << Arel.sql('grade_entry_students.total_grade as total_marks')
    end

    if current_role.instructor?
      students = grade_entry_form.grade_entry_students
                                 .joins(role: :user)
                                 .pluck_to_hash(*student_pluck_attrs)
      grades = grade_entry_form.grade_entry_students
                               .joins(:grades)
                               .pluck(:id, 'grades.grade_entry_item_id', 'grades.grade')
                               .group_by { |x| x[0] }
    elsif current_role.ta?
      students = current_role.grade_entry_students
                             .where(grade_entry_form: grade_entry_form)
                             .joins(role: :user)
                             .pluck_to_hash(*student_pluck_attrs)
      grades = current_role.grade_entry_students
                           .where(grade_entry_form: grade_entry_form)
                           .joins(:grades)
                           .pluck(:id, 'grades.grade_entry_item_id', 'grades.grade')
                           .group_by { |x| x[0] }
    end

    student_grades = students.map do |s|
      (grades[s[:_id]] || []).each do |_, grade_entry_item_id, grade|
        s[grade_entry_item_id] = grade
      end
      if grade_entry_form.show_total && s[:total_marks].nil?
        s[:total_marks] = t(:not_applicable)
      end
      s
    end
    render json: { data: student_grades,
                   sections: current_course.sections.pluck(:id, :name).to_h }
  end

  # Release/unrelease the marks for all the students or for a subset of students
  def update_grade_entry_students
    if params[:students].blank?
      flash_message(:warning, I18n.t('grade_entry_forms.grades.select_a_student'))
    else
      grade_entry_form = record
      release = params[:release_results] == 'true'
      GradeEntryStudent.transaction do
        data = record.course
                     .students
                     .joins(:grade_entry_students)
                     .where('grade_entry_students.assessment_id': grade_entry_form.id,
                            'grade_entry_students.id': params[:students])
                     .pluck('grade_entry_students.id', 'roles.id')
                     .map { |ges_id, r_id| { id: ges_id, role_id: r_id, released_to_student: release } }
        GradeEntryStudent.upsert_all(data)
        num_changed = data.length
        flash_message(:success, I18n.t('grade_entry_forms.grades.successfully_changed',
                                       numGradeEntryStudentsChanged: num_changed))
        action = release ? 'released' : 'unreleased'
        log_message = "#{action} #{num_changed} for marks spreadsheet '#{grade_entry_form.short_identifier}'."
        MarkusLogger.instance.log(log_message)
      rescue StandardError => e
        flash_message(:error, e.message)
        raise ActiveRecord::Rollback
      end
      GradeEntryStudent.where(id: params[:students]).includes(:role).each do |current_student|
        if current_student.role.receives_results_emails?
          NotificationMailer.with(student: current_student, form: grade_entry_form, course: current_course)
                            .release_spreadsheet_email.deliver_later
        end
      end
    end
  end

  # Download the grades for this grade entry form as a CSV file
  def download
    grade_entry_form = record
    send_data grade_entry_form.export_as_csv(current_role),
              disposition: 'attachment',
              type: 'text/csv',
              filename: "#{grade_entry_form.short_identifier}_grades_report.csv"
  end

  # Upload the grades for this grade entry form using a CSV file
  def upload
    @grade_entry_form = record
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        overwrite = params[:overwrite]
        grades_file = data[:file]
        result = @grade_entry_form.from_csv(grades_file.read, overwrite)
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      end
    end
    redirect_to action: 'grades', id: @grade_entry_form.id
  end

  def grade_distribution
    grade_entry_form = record

    intervals = 20
    dict_data = grade_entry_form.grade_entry_items.map do |item|
      { label: item.name, data: item.grade_distribution_array(intervals) }
    end
    column_breakdown_data = {
      labels: (0..intervals - 1).map { |i| "#{5 * i}-#{5 * i + 5}" },
      datasets: dict_data
    }

    grade_dist_data = {
      labels: (0..intervals - 1).map { |i| "#{5 * i}-#{5 * i + 5}" },
      datasets: [{ data: grade_entry_form.grade_distribution_array(intervals) }]
    }

    summary = {
      name: "#{grade_entry_form.short_identifier}: #{grade_entry_form.description}",
      date: I18n.l(grade_entry_form.due_date),
      average: grade_entry_form.results_average(points: true) || 0,
      median: grade_entry_form.results_median(points: true) || 0,
      standard_deviation: grade_entry_form.results_standard_deviation || 0,
      max_mark: grade_entry_form.max_mark,
      num_entries: grade_entry_form.count_non_nil,
      groupings_size: grade_entry_form.grade_entry_students.joins(:role).where('roles.hidden': false).count,
      num_fails: grade_entry_form.results_fails,
      num_zeros: grade_entry_form.results_zeros
    }

    render json: {
      assessment_data: grade_dist_data,
      secondary_assessment_data: column_breakdown_data,
      summary: summary
    }
  end

  def switch
    redirect_options = referer_options

    if redirect_options[:controller] == 'grade_entry_forms'
      redirect_options[:id] = params[:id]
      redirect_to redirect_options
    elsif redirect_options[:grade_entry_form_id]
      redirect_options[:grade_entry_form_id] = params[:id]
      redirect_to redirect_options
    elsif current_role.instructor?
      redirect_to edit_course_grade_entry_form_path(current_course, params[:id])
    elsif current_role.ta?
      redirect_to grades_course_grade_entry_form_path(current_course, params[:id])
    else # current_role.student?
      redirect_to student_interface_course_grade_entry_form_path(current_course, params[:id])
    end
  end
end
