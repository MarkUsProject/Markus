# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  include GradeEntryFormsHelper

  before_action :authorize_only_for_admin,
                except: [:student_interface,
                         :populate_grades_table,
                         :get_mark_columns,
                         :grades,
                         :download,
                         :upload,
                         :update_grade]
  before_action :authorize_for_ta_and_admin,
                only: [:grades,
                       :populate_grades_table,
                       :download,
                       :upload,
                       :update_grade]
  before_action :authorize_for_student,
                only: [:student_interface]

  layout 'assignment_content'

  responders :flash

  # Create a new grade entry form
  def new
    @grade_entry_form = GradeEntryForm.new
  end

  def create
    # Edit params before updating model
    new_params = update_grade_entry_form_params(params)

    @grade_entry_form = GradeEntryForm.create(new_params)
    respond_with(@grade_entry_form, location: -> { edit_grade_entry_form_path(@grade_entry_form) })
  end

  # Edit the properties of a grade entry form
  def edit
    @grade_entry_form = GradeEntryForm.find(params[:id])
  end

  def update
    @grade_entry_form = GradeEntryForm.find(params[:id])

    # Process changes to input properties
    new_params = update_grade_entry_form_params(params)

    @grade_entry_form.update(new_params)
    respond_with(@grade_entry_form, location: -> { edit_grade_entry_form_path @grade_entry_form })
  end

  # View/modify the grades for this grade entry form
  def grades
    @grade_entry_form = GradeEntryForm.find(params[:id])
  end

  def view_summary
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @grade_entry_items = @grade_entry_form.grade_entry_items unless @grade_entry_form.nil?
    @date = params[:date]
  end

  # Update a grade in the table
  def update_grade
    grade_entry_form = GradeEntryForm.find(params[:id])
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
    @grade_entry_form = GradeEntryForm.find(params[:id])
    if @grade_entry_form.is_hidden
      render 'shared/http_status',
             formats: [:html],
             locals: {
               code: '404',
               message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: 404,
             layout: false
      return
    end

    # Getting the student's marks for each grade entry item
    @grade_entry_student = @grade_entry_form.grade_entry_students.find_by(user_id: current_user.id)
    @columns = []
    @data = []
    @grade_entry_form.grade_entry_items.each do |grade_entry_item|
      @columns << "#{grade_entry_item.name} (#{grade_entry_item.out_of})"
      mark = @grade_entry_student.grades.find_by(grade_entry_item_id: grade_entry_item.id)
      if !mark.nil? && !mark.grade.nil?
        @data << mark.grade
      else
        @data << t('grade_entry_forms.grades.no_mark')
      end
    end

    # Get data for the total marks column
    if @grade_entry_form.show_total
      @columns << "#{GradeEntryForm.human_attribute_name(:total)} (#{@grade_entry_form.out_of_total})"
      total = @grade_entry_student.total_grade
      if !total.nil?
        @data << total
      else
        @data << t('grade_entry_forms.grades.no_mark')
      end
    end
  end

  def get_mark_columns
    grade_entry_form = GradeEntryForm.find(params[:id])
    data = grade_entry_form.grade_entry_items.map do |column|
      {
        accessor: column.id.to_s,
        Header: "#{column.name} (#{column.out_of})"
      }
    end
    render json: data
  end

  def populate_grades_table
    grade_entry_form = GradeEntryForm.find(params[:id])
    student_pluck_attrs = [
      Arel.sql('grade_entry_students.id as _id'),
      :released_to_student,
      Arel.sql('users.user_name as user_name'),
      Arel.sql('users.first_name as first_name'),
      Arel.sql('users.last_name as last_name'),
      Arel.sql('users.hidden as hidden'),
      Arel.sql('users.section_id as section_id')
    ]
    if grade_entry_form.show_total
      student_pluck_attrs << Arel.sql('grade_entry_students.total_grade as total_marks')
    end

    if current_user.admin?
      students = grade_entry_form.grade_entry_students
                                 .joins(:user)
                                 .pluck_to_hash(*student_pluck_attrs)
      grades = grade_entry_form.grade_entry_students
                               .joins(:grades)
                               .pluck(:id, 'grades.grade_entry_item_id', 'grades.grade')
                               .group_by { |x| x[0] }
    elsif current_user.ta?
      students = current_user.grade_entry_students
                             .where(grade_entry_form: grade_entry_form)
                             .joins(:user)
                             .pluck_to_hash(*student_pluck_attrs)
      grades = current_user.grade_entry_students
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
        s[:total_marks] = t('grade_entry_forms.grades.no_mark')
      end
      s
    end
    render json: { data: student_grades,
                   sections: Hash[Section.all.pluck(:id, :name)] }
  end

  # Release/unrelease the marks for all the students or for a subset of students
  def update_grade_entry_students
    if params[:students].blank?
      flash_message(:warning, I18n.t('grade_entry_forms.grades.select_a_student'))
    else
      grade_entry_form = GradeEntryForm.find_by_id(params[:id])
      release = params[:release_results] == 'true'
      GradeEntryStudent.transaction do
        GradeEntryStudent.upsert_all(params[:students].map { |id| { id: id, released_to_student: release } })
        num_changed = params[:students].length
        flash_message(:success, I18n.t('grade_entry_forms.grades.successfully_changed',
                                       numGradeEntryStudentsChanged: num_changed))
        action = release ? 'released' : 'unreleased'
        log_message = "#{action} #{num_changed} for marks spreadsheet '#{grade_entry_form.short_identifier}'."
        MarkusLogger.instance.log(log_message)
      rescue StandardError => e
        flash_message(:error, e.message)
        raise ActiveRecord::Rollback
      end
    end
  end

  # Download the grades for this grade entry form as a CSV file
  def download
    grade_entry_form = GradeEntryForm.find(params[:id])
    send_data grade_entry_form.export_as_csv,
              disposition: 'attachment',
              type: 'text/csv',
              filename: "#{grade_entry_form.short_identifier}_grades_report.csv"
  end

  # Upload the grades for this grade entry form using a CSV file
  def upload
    @grade_entry_form = GradeEntryForm.find(params[:id])
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
end
