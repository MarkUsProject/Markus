# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  include GradeEntryFormsPaginationHelper
  include GradeEntryFormsHelper

  before_filter :authorize_only_for_admin,
                except: [:student_interface,
                         :populate_term_marks_table,
                         :get_mark_columns,
                         :grades,
                         :g_table_paginate,
                         :csv_download,
                         :csv_upload,
                         :update_grade]
  before_filter :authorize_for_ta_and_admin,
                only: [:grades,
                       :populate_grades_table,
                       :g_table_paginate,
                       :csv_download,
                       :csv_upload,
                       :update_grade]
  before_filter :authorize_for_student,
                only: [:student_interface,
                       :populate_term_marks_table]

  # Filters will be added as the student UI is implemented (eg. Show Released,
  # Show All,...)
  G_TABLE_PARAMS = {model: GradeEntryStudent,
                    per_pages: [100, 150, 500, 1000],
                    filters: {
                        'none' => {
                            display: 'Show All',
                            proc: lambda { |sort_by, order, user|
                              if user.instance_of? Admin
                                conditions = {hidden: false}
                              else
                                #Display only students to which the TA has been assigned
                                conditions = {hidden: false, id:
                                    Ta.find(user.id).grade_entry_students.all(select: :user_id).collect(&:user_id)}
                              end

                              if sort_by.present?
                                if sort_by == 'section'
                                  Student.includes(:section).all(conditions: conditions,
                                                              order: 'sections.name ' + order)
                                else
                                  Student.all(conditions: conditions,
                                              order: sort_by + ' ' + order)
                                end
                              else
                                Student.all(conditions: conditions,
                                            order: 'user_name ' + order)
                              end
                            }}}
  }

  # Create a new grade entry form
  def new
    @grade_entry_form = GradeEntryForm.new
  end

  def create
    @grade_entry_form = GradeEntryForm.new

    # Process input properties
    @grade_entry_form.transaction do
      # Edit params before updating model
      new_params = update_grade_entry_form_params grade_entry_form_params
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
      new_params = update_grade_entry_form_params grade_entry_form_params
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
    @filter = 'none'

    @current_page = 1

    # The cookies are handled here
    c_per_page = cookie_per_page_name
    if params[:per_page].present?
      cookies[c_per_page] = params[:per_page]
    elsif cookies[c_per_page].present?
      params[:per_page] = cookies[c_per_page]
    else
      # Set params to default and make the cookie!
      params[:per_page] = 100
      cookies[c_per_page] = params[:per_page]
    end

    c_sort_by = current_user.id.to_s + '_' +
        @grade_entry_form.id.to_s + '_sort_by_grades'
    if params[:sort_by].present?
      cookies[c_sort_by] = params[:sort_by]
    elsif cookies[c_sort_by].present?
      params[:sort_by] = cookies[c_sort_by]
    else
      params[:sort_by] = 'last_name'
      cookies[c_sort_by] = params[:sort_by]
    end
    @sort_by = params[:sort_by]
    @desc = params[:desc]
    @filters = get_filters(G_TABLE_PARAMS)
    @per_page = params[:per_page]
    @per_pages = G_TABLE_PARAMS[:per_pages]
    @loc = params

    # Create cookie to remember the direction of the sort
    c_order = current_user.id.to_s + '_' +
        @grade_entry_form.id.to_s + '_order_sp'
    if !cookies[c_order].blank? && !params[:loc].present?
      @desc = cookies[c_order]
    elsif @desc.blank?
      cookies[c_order] = ''
    else
      cookies[c_order] = @desc
    end

    all_students = get_filtered_items(G_TABLE_PARAMS,
                                      @filter,
                                      @sort_by,
                                      @desc)
    @students = all_students.paginate(per_page: @per_page,
                                      page: @current_page)
    @students_total = all_students.size
    @alpha_pagination_options =
                      @grade_entry_form.alpha_paginate(all_students,
                                                       @per_page,
                                                       @students.total_pages,
                                                       @sort_by)
    session[:alpha_pagination_options] = @alpha_pagination_options
    @alpha_category = @alpha_pagination_options.first
  end

  
  # Handle pagination for grades table
  # (The algorithm used to compute the alphabetical categories
  # (alpha_paginate()) is
  # found in grade_entry_form.rb.)
  def g_table_paginate
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @students, @students_total = handle_paginate_event(
        G_TABLE_PARAMS,
        {grade_entry_form: @grade_entry_form},
        params)
    # It is important to set the :per_page cookie during Ajax Request as well
    c_per_page = cookie_per_page_name
    if params[:per_page].present?
      cookies[c_per_page] = params[:per_page]
    elsif cookies[c_per_page].present?
      params[:per_page] = cookies[c_per_page]
    end
    @current_page = params[:page]
    @per_page = params[:per_page]
    @filters = get_filters(G_TABLE_PARAMS)
    @per_pages = G_TABLE_PARAMS[:per_pages]
    @desc = params[:desc]
    @filter = params[:filter]
    c_sort_by = current_user.id.to_s + '_' +
        @grade_entry_form.id.to_s + '_sort_by_grades'
    if params[:sort_by].present?
      @sort_by = params[:sort_by]
    elsif cookies[c_sort_by].present?
      params[:sort_by] = cookies[c_sort_by]
    end

    @sort_by = params[:sort_by]

    # Only re-compute the alpha_pagination_options for the drop-down menu
    # if the number of items per page has changed
    if params[:update_alpha_pagination_options] == 'true'
      all_students = get_filtered_items(
          G_TABLE_PARAMS,
          @filter,
          @sort_by,
          @desc)
      @alpha_pagination_options = @grade_entry_form.alpha_paginate(
          all_students,
          @per_page,
          @students.total_pages,
          @sort_by)
      @alpha_category = @alpha_pagination_options.first
      session[:alpha_pagination_options] = @alpha_pagination_options
    else
      @alpha_pagination_options = session[:alpha_pagination_options]
      @alpha_category = params[:alpha_category]
    end
  end

  # Cookie name
  def cookie_per_page_name
    "#{current_user.id}_#{@grade_entry_form.id}_per_page_sp"
  end
  
  # Update a grade in the table
  def update_grade
    grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    @student_id = params[:student_id]
    @grade_entry_item_id = params[:grade_entry_item_id]
    updated_grade = params[:updated_grade]

    grade_entry_student = grade_entry_form.grade_entry_students
                          .find_or_create_by_user_id(@student_id)

    @grade = grade_entry_student.grades.find_or_create_by_grade_entry_item_id(
                  @grade_entry_item_id)

    @grade.grade = updated_grade
    @grade_saved = @grade.save
    @updated_student_total = grade_entry_student.total_grade

    grade_entry_student.save # Save updated grade
  end

  # For students
  def student_interface
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @student = current_user
  end

  def get_mark_columns
    grade_entry_form = GradeEntryForm.find(params[:id])
    grade_entry_items_columns = grade_entry_form.grade_entry_items
    c = grade_entry_items_columns.map do |column|
      {
        id: column.id,
        content: column.name + ' (' + column.out_of.to_s + ')',
      }
    end
    if grade_entry_form.show_total
      c <<
        {
          id: 'total_marks',
          content: t('grade_entry_forms.grades.total') \
                   + ' ' + grade_entry_form.out_of_total.to_s,
        }
    end
    if current_user.admin? || current_user.ta?
      c <<
        {
          id: 'marking_state',
          content: t('grade_entry_forms.grades.marking_state')
        }
    end

    render json: c
  end

  def populate_grades_table
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @students = Student.all

    @student_grades = @students.map do |student|
      s = student.attributes
      student_grade_entry = @grade_entry_form.grade_entry_students
                            .find_by_user_id(student.id)
      if !student_grade_entry.nil?
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
        grade_entry_students.push(grade_entry_form.grade_entry_students
          .find_or_create_by_user_id(student_id))
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

    redirect_to action: 'grades', id: params[:id]
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
    end

    #If the request is a post type and the abort flag is down (operation can continue)
    if request.post? && !abort_upload
      grades_file = params[:upload][:grades_file]
      begin
        GradeEntryForm.transaction do
          invalid_lines = []
          num_updates = GradeEntryForm.parse_csv(grades_file,
                                                 @grade_entry_form,
                                                 invalid_lines,
                                                 encoding)
          unless invalid_lines.empty?
            flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
          end
          if num_updates > 0
            flash[:notice] = I18n.t('grade_entry_forms.csv.upload_success',
                                    num_updates: num_updates)
          end
        end
      end
    end
    redirect_to action: 'grades', id: @grade_entry_form.id
  end

  private

  def grade_entry_form_params
    params.require(:grade_entry_form).permit(:description,
                                             :message,
                                             :date,
                                             :show_total,
                                             :short_identifier)
  end
end
