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
        flash[:success] = I18n.t('grade_entry_forms.create.success')
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
        flash[:success] = I18n.t('grade_entry_forms.edit.success')
        redirect_to action: 'edit', id: @grade_entry_form.id
      else
        render 'edit', id: @grade_entry_form.id
      end
    end
  end

  # View/modify the grades for this grade entry form
  def grades
    @grade_entry_form = GradeEntryForm.find(params[:id])
    render layout: 'assignment_content'
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
    @grade_entry_form = GradeEntryForm.find(params[:id])
    if current_user.admin?
      @students = Student.all
    elsif current_user.ta?
      @students = current_user.grade_entry_students.map(&:user)
    end

    @student_grades = @students.map do |student|
      s = student.attributes
      student_grade_entry = @grade_entry_form.grade_entry_students
                                             .find_by_user_id(student.id)
      s[:section] = student.section.try(:name)
      unless student_grade_entry.nil?
        # Populate grades
        @grade_entry_form.grade_entry_items.each do |grade_entry_item|
          s[:grade_entry_form] = @grade_entry_form.id
          @mark = student_grade_entry.grades
                  .find_by_grade_entry_item_id(grade_entry_item.id)
          if !@mark.nil? && !@mark.grade.nil?
            s[grade_entry_item.id] = @mark.grade
          end
        end
        # Populate marking state
        if student_grade_entry.released_to_student
          s[:marking_state] = ActionController::Base.helpers
                              .asset_path('icons/email_go.png')
        end
        # Populate grade total
        if @grade_entry_form.show_total
          total = student_grade_entry.total_grade
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
      flash[:success] = I18n.t('grade_entry_forms.grades.successfully_changed',
                               {numGradeEntryStudentsChanged: numGradeEntryStudentsChanged})
      m_logger = MarkusLogger.instance
      m_logger.log(log_message)
    end
    flash[:error] = errors

    head :ok
  end

  # Download the grades for this grade entry form as a CSV file
  def csv_download
    grade_entry_form = GradeEntryForm.find(params[:id])
    send_data grade_entry_form.get_csv_grades_report,
              disposition: 'attachment',
              type: 'application/vnd.ms-excel',
              filename: "#{grade_entry_form.short_identifier}_grades_report.csv"
  end

  # Upload the grades for this grade entry form using a CSV file
  def csv_upload

    @grade_entry_form = GradeEntryForm.find(params[:id])

    encoding = params[:encoding]
    upload = params[:upload]
    overwrite = params[:overwrite]

    #flag to check whether upload should continue. True if upload should be aborted
    abort_upload = false

    #Did the user upload a file?
    if upload.blank?
      flash[:error] = "No file selected!"
      abort_upload = true
    else
      filename = params[:upload][:grades_file].original_filename
      filename_extension = filename[-4, 4]
      if filename_extension != ".csv"
        abort_upload = true
        flash[:error] = "You did not upload a .csv file."
      end
      # Replace non-UNIX line endings with standard CR+LF style
      if (reader = File.read(params[:upload][:grades_file].path.to_s,
                             mode: 'rb'))
        replaced_newlines = reader.gsub!(/\r\n?|\n/, "\r\n")
        unless replaced_newlines == nil
          File.open(params[:upload][:grades_file].path.to_s, 'wb') do |f|
            f.write(replaced_newlines + "\r\n")
          end
        end
      end
    end

    # If the request is a post type and the abort flag is down
    # (operation can continue)
    if request.post? && !abort_upload
      grades_file = params[:upload][:grades_file]
      begin
        GradeEntryForm.transaction do
          invalid_lines = []
          num_updates = GradeEntryForm.parse_csv(grades_file,
                                                 @grade_entry_form,
                                                 invalid_lines,
                                                 encoding, overwrite)
          unless invalid_lines.empty?
            flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
          end
          if num_updates > 0
            flash[:notice] = I18n.t('grade_entry_forms.csv.upload_success',
                                    num_updates: num_updates)
          end
        end
      rescue CSV::MalformedCSVError
        flash[:error] = t('csv.upload.malformed_csv')
      rescue ArgumentError
        flash[:error] = I18n.t('csv.upload.non_text_file_with_csv_extension')
      end
    end
    redirect_to action: 'grades', id: @grade_entry_form.id
  end
end
