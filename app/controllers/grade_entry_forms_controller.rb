# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  include GradeEntryFormsHelper

  before_filter :authorize_only_for_admin,
                except: [:student_interface,
                         :populate_term_marks_table,
                         :populate_grades_table,
                         :get_mark_columns,
                         :grades,
                         :csv_download,
                         :csv_upload,
                         :update_grade]
  before_filter :authorize_for_ta_and_admin,
                only: [:grades,
                       :populate_grades_table,
                       :csv_download,
                       :csv_upload,
                       :update_grade]
  before_filter :authorize_for_student,
                only: [:student_interface,
                       :populate_term_marks_table]

  layout 'assignment_content'

  # Create a new grade entry form
  def new
    @grade_entry_form = GradeEntryForm.new
  end

  def create
    @grade_entry_form = GradeEntryForm.new

    # Process input properties
    @grade_entry_form.transaction do
      # Edit params before updating model
      new_params = update_grade_entry_form_params(params)
      if @grade_entry_form.update_attributes(new_params)
        # Success message
        flash_message(:success, I18n.t('grade_entry_forms.create.success'))
        redirect_to action: 'edit', id: @grade_entry_form.id
      else
        render 'new'
      end
    end
  end

  # Edit the properties of a grade entry form
  def edit
    @grade_entry_form = GradeEntryForm.find(params[:id])
  end

  def update
    @grade_entry_form = GradeEntryForm.find(params[:id])

    # Process changes to input properties
    @grade_entry_form.transaction do

      # Edit params before updating model

      new_params = update_grade_entry_form_params(params)

      if params[:date_check]
        new_params.update(date: nil)
      end

      if @grade_entry_form.update_attributes(new_params)
        # Success message
        flash_message(:success, I18n.t('grade_entry_forms.edit.success'))
        redirect_to action: 'edit', id: @grade_entry_form.id
      else
        render 'edit', id: @grade_entry_form.id
      end
    end
  end

  # View/modify the grades for this grade entry form
  def grades
    @sections = Section.order(:name)
    @grade_entry_form = GradeEntryForm.find(params[:id])
  end

  # Update a grade in the table
  def update_grade
    grade_entry_form = GradeEntryForm.find(params[:id])
    @student_id = params[:student_id]
    @grade_entry_item_id = params[:grade_entry_item_id]
    updated_grade = params[:updated_grade]

    grade_entry_student =
      grade_entry_form.grade_entry_students.find_or_create_by(user_id:
            @student_id)

    @grade = grade_entry_student.grades.find_or_create_by(grade_entry_item_id:
                  @grade_entry_item_id)

    @grade.grade = updated_grade
    @grade_saved = @grade.save
    @updated_student_total = grade_entry_student.total_grade

    grade_entry_student.save # Save updated grade
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
    @student = current_user
  end

  def get_mark_columns
    grade_entry_form = GradeEntryForm.find(params[:id])
    grade_entry_items_columns = grade_entry_form.grade_entry_items
    c = grade_entry_items_columns.map do |column|
      {
        id: column.id,
        content: column.name + ' (' + column.out_of.to_s + ')',
        sortable: true,
        compare: 'compare_gradebox'
      }
    end
    if grade_entry_form.show_total
      c <<
        {
          id: 'total_marks',
          content: t('grade_entry_forms.grades.total') \
                   + ' ' + grade_entry_form.out_of_total.to_s,
          sortable: true,
          compare: 'compare_gradebox'
        }
    end
    if current_user.admin? || current_user.ta?
      c <<
        {
          id: 'marking_state',
          content: t('grade_entry_forms.grades.marking_state'),
          sortable: true
        }
    end

    render json: c
  end

  def populate_grades_table
    @grade_entry_form = GradeEntryForm.includes(grade_entry_students:
                                                  [:grades, { user: :section }])
                                      .find(params[:id])
    if current_user.admin?
      @students = Student.all
    elsif current_user.ta?
      @students = current_user.grade_entry_students.map(&:user)
    end

    # TODO: Remove this hack by putting a computed column for the total_grade attribute
    totals = Grade.where(grade_entry_student_id:
                           @grade_entry_form.grade_entry_students.pluck(:id))
                  .group(:grade_entry_student_id)
                  .sum(:grade)

    @student_grades = @grade_entry_form.grade_entry_students.map do |student_grade_entry|
      student = student_grade_entry.user
      s = student.attributes
      s[:section] = student.section.try(:name) || '-'
      unless student_grade_entry.nil?
        student_grade_entry.grades.each do |grade|
          s[grade.grade_entry_item_id] = grade.grade
        end
        # Populate marking state
        if student_grade_entry.released_to_student
          s[:marking_state] = ActionController::Base.helpers
                              .asset_path('icons/email_go.png')
        end
        # Populate grade total
        if @grade_entry_form.show_total
          total = totals[student_grade_entry.id]
          if !total.nil?
            s[:total_marks] = total
          else
            s[:total_marks] = t('grade_entry_forms.grades.no_mark')
          end
        end
      end
      s
    end
    render json: @student_grades
  end

  def populate_term_marks_table
    grade_entry_form = GradeEntryForm.find(params[:id])
    student = current_user
    student_grade_entry = grade_entry_form.grade_entry_students
                          .find_by_user_id(student.id)

    # Getting the student's information for the row
    row = {}
    row[:user_name] = student.user_name
    row[:first_name] = student.first_name
    row[:last_name] = student.last_name

    # Getting the student's marks for each grade entry item
    grade_entry_form.grade_entry_items.each do |grade_entry_item|
      mark = student_grade_entry.grades
             .find_by_grade_entry_item_id(grade_entry_item.id)
      if !mark.nil? && !mark.grade.nil?
        row[grade_entry_item.id] = mark.grade
      else
        row[grade_entry_item.id] = t('grade_entry_forms.grades.no_mark')
      end
    end

    # Get data for the total marks column
    if grade_entry_form.show_total
      total = student_grade_entry.total_grade
      if !total.nil?
        row[:total_marks] = total
      else
        row[:total_marks] = t('grade_entry_forms.grades.no_mark')
      end
    end

    render json: row
  end

  # Release/unrelease the marks for all the students or for a subset of students
  def update_grade_entry_students
    return unless request.post?

    grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    errors = []
    grade_entry_students = []

    if params[:students].nil?
      errors.push(I18n.t('grade_entry_forms.grades.must_select_a_student'))
    else
      params[:students].each do |student_id|
        grade_entry_students.push(
          grade_entry_form.grade_entry_students
                          .find_or_create_by(user_id: student_id))
      end
    end

    # Releasing/unreleasing marks should be logged
    log_message = ''
    if params[:release_results]
      numGradeEntryStudentsChanged = set_release_on_grade_entry_students(
          grade_entry_students,
          true,
          errors)
      log_message = "Marks released for marks spreadsheet '" +
          "#{grade_entry_form.short_identifier}', ID: '#{grade_entry_form.id}' " +
          "(for #{numGradeEntryStudentsChanged} students)."
    elsif !params[:unrelease_results].nil?
      numGradeEntryStudentsChanged = set_release_on_grade_entry_students(
          grade_entry_students,
          false,
          errors)
      log_message = "Marks unreleased for marks spreadsheet '" +
          "#{grade_entry_form.short_identifier}', ID: '#{grade_entry_form.id}' " +
          "(for #{numGradeEntryStudentsChanged} students)."
    end

    # Display success message
    if numGradeEntryStudentsChanged > 0
      flash_message(:success, I18n.t('grade_entry_forms.grades.successfully_changed',
                                     {numGradeEntryStudentsChanged: numGradeEntryStudentsChanged}))
      m_logger = MarkusLogger.instance
      m_logger.log(log_message)
    end
    flash_message(:error, errors)

    head :ok
  end

  # Download the grades for this grade entry form as a CSV file
  def csv_download
    grade_entry_form = GradeEntryForm.find(params[:id])
    students = Student.where(hidden: false).order(:user_name)
    grade_entry_items = grade_entry_form.grade_entry_items
    csv_rows = []
    # prepare first two csv rows
    # The first row in the CSV file will contain the question names
    row = ['']
    grade_entry_items.each do |grade_entry_item|
      row.push(grade_entry_item.name)
    end
    csv_rows.push(row)
    # The second row in the CSV file will contain the question totals
    row = ['']
    grade_entry_items.each do |grade_entry_item|
      row.push(grade_entry_item.out_of)
    end
    csv_rows.push(row)
    # The rest of the rows in the CSV file will contain the students' grades
    form_data = MarkusCSV.generate(students, csv_rows) do |student|
      row = []
      row.push(student.user_name)
      grade_entry_student = grade_entry_form.grade_entry_students
        .where(user_id: student.id)
        .first
      # Check whether or not we have grades recorded for this student
      if grade_entry_student.nil?
        grade_entry_items.each do |grade_entry_item|
          # Blank marks for each question
          row.push('')
        end
        # Blank total percent
        row.push('')
      else
        grade_entry_items.each do |grade_entry_item|
          grade = grade_entry_student
            .grades
            .where(grade_entry_item_id: grade_entry_item.id)
            .first
          if grade.nil?
            row.push('')
          else
            row.push(grade.grade || '')
          end
        end
        total_percent = grade_entry_form
          .calculate_total_percent(grade_entry_student)
        row.push(total_percent)
      end
      row
    end
    send_data form_data,
              disposition: 'attachment',
              type: 'text/csv',
              filename: "#{grade_entry_form.short_identifier}_grades_report.csv"
  end

  # Upload the grades for this grade entry form using a CSV file
  def csv_upload
    @grade_entry_form = GradeEntryForm.includes(grade_entry_students: [:grades, :user])
                                      .find(params[:id])

    # If the request is a post type and the abort flag is down
    # (operation can continue)
    if request.post? && params[:upload] && params[:upload][:grades_file]
      grades_file = params[:upload][:grades_file]
      encoding = params[:encoding]
      overwrite = params[:overwrite]
      names = ''
      totals = ''
      columns = []

      # Parse the grades
      result = MarkusCSV.parse(grades_file.read, encoding: encoding) do |row|
        next if CSV.generate_line(row).strip.empty?
        # grab names and totals from the first two rows
        if names.empty?
          names = row
          next
        end
        if totals.empty?
          totals = row
          # Create/update the grade entry items
          GradeEntryItem.create_or_update_from_csv_rows(
            names,
            totals,
            @grade_entry_form,
            overwrite)
          next
        end
        columns = @grade_entry_form.grade_entry_items.reload
        grade_list = @grade_entry_form.grades.map do |g|
          [[g.grade_entry_student_id, g.grade_entry_item_id], g.grade]
        end
        all_grades = Hash[grade_list]
        Upsert.batch(ActiveRecord::Base.connection, Grade.table_name) do |upsert|

          s = @grade_entry_form.grade_entry_students
                               .joins(:user)
                               .find_by('users.user_name' => row[0].encode('UTF-8'))
          raise CSVInvalidLineError if s.nil?

          row.shift
          row.zip(columns.take(row.size)).each do |grade, c|
            new_grade = grade.blank? ? nil : Float(grade)
            selector = { grade_entry_student_id: s.id,
                         grade_entry_item_id: c.id }
            if s.nil? || overwrite
              setter = { grade: new_grade }
            else
              setter = { grade: all_grades[[s.id, c.id]] || new_grade }
            end
            upsert.row(selector, setter)
          end
        end
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
    end
    redirect_to action: 'grades', id: @grade_entry_form.id
  end
end
