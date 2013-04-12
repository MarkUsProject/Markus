# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  include GradeEntryFormsPaginationHelper
  include GradeEntryFormsHelper

  before_filter      :authorize_only_for_admin,
                     :except => [:student_interface,
                                 :grades,
                                 :g_table_paginate,
                                 :csv_download,
                                 :csv_upload,
                                 :update_grade]
  before_filter      :authorize_for_ta_and_admin,
                     :only => [:grades,
                               :g_table_paginate,
                               :csv_download,
                               :csv_upload,
                               :update_grade]
  before_filter      :authorize_for_student,
                      :only => [:student_interface]

  # Filters will be added as the student UI is implemented (eg. Show Released,
  # Show All,...)
  G_TABLE_PARAMS = {:model => GradeEntryStudent,
                    :per_pages => [15, 30, 50, 100, 150],
                    :filters => {'none' => {
                                     :display => 'Show All',
                                     :proc => lambda { |sort_by, order, user|
                                          if user.type == "Admin"
                                            conditions = {:hidden => false}
                                          else #Display only students to which the TA has been assigned
                                            conditions = {:hidden => false, :id => Ta.find(user.id).grade_entry_students.all(:select => :user_id).collect(&:user_id)}
                                          end

                                          if !sort_by.blank?
                                            if sort_by == "section"
                                              Student.joins(:section).all(:conditions => conditions,
                                                  :order => "sections.name "+order)
                                            else
                                              Student.all(:conditions => conditions,
                                                :order => sort_by+" "+order)
                                            end
                                          else
                                            Student.all(:conditions => conditions,
                                              :order => "user_name "+order)
                                          end }}}
                        }

  # Create a new grade entry form
  def new
    @grade_entry_form = GradeEntryForm.new
  end

  def create
    @grade_entry_form = GradeEntryForm.new

    # Process input properties
    @grade_entry_form.transaction do
      if @grade_entry_form.update_attributes(params[:grade_entry_form])
        # Success message
        flash[:success] = I18n.t('grade_entry_forms.create.success')
        redirect_to :action => "edit", :id => @grade_entry_form.id
      else
        render "new"
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
      if @grade_entry_form.update_attributes(params[:grade_entry_form])
        # Success message
        flash[:success] = I18n.t('grade_entry_forms.edit.success')
        redirect_to :action => "edit", :id => @grade_entry_form.id
      else
        render "edit", :id => @grade_entry_form.id
      end
    end
  end

  # View/modify the grades for this grade entry form
  def grades
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @filter = 'none'

    # Pagination options
    if(!params[:per_page].blank?)
      @per_page = params[:per_page]
    else
      @per_page = 15
    end

    @current_page = 1
    c_sort_by = current_user.id.to_s +  "_"+ @grade_entry_form.id.to_s+ "_sort_by_grades"
    if !params[:sort_by].blank?
      cookies[c_sort_by] = params[:sort_by]
    else
      params[:sort_by] = 'last_name'
    end
    @sort_by = cookies[c_sort_by]
    @desc = params[:desc]
    @filters = get_filters(G_TABLE_PARAMS)
    @per_pages = G_TABLE_PARAMS[:per_pages]

    all_students = get_filtered_items(G_TABLE_PARAMS,
                                      @filter,
                                      @sort_by,
                                      params[:desc])
    @students = all_students.paginate(:per_page => @per_page,
                                      :page => @current_page)
    @students_total = all_students.size
    @alpha_pagination_options = @grade_entry_form.alpha_paginate(all_students,
                                                        @per_page,
                                                        @students.total_pages)
    session[:alpha_pagination_options] = @alpha_pagination_options
    @alpha_category = @alpha_pagination_options.first
    @sort_by = cookies[c_sort_by]
  end

  # Handle pagination for grades table
  # (The algorithm used to compute the alphabetical categories
  # (alpha_paginate()) is
  # found in grade_entry_form.rb.)
  def g_table_paginate
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @students, @students_total = handle_paginate_event(
                                   G_TABLE_PARAMS,
                                   {:grade_entry_form => @grade_entry_form},
                                   params)

    @current_page = params[:page]
    @per_page = params[:per_page]
    @filters = get_filters(G_TABLE_PARAMS)
    @per_pages = G_TABLE_PARAMS[:per_pages]
    @desc = params[:desc]
    @filter = params[:filter]
    if !params[:sort_by].blank?
      @sort_by = params[:sort_by]
    else
      @sort_by = 'last_name'
    end

    # Only re-compute the alpha_pagination_options for the drop-down menu
    # if the number of items per page has changed
    if params[:update_alpha_pagination_options] == "true"
      all_students = get_filtered_items(
                       G_TABLE_PARAMS,
                       @filter,
                       @sort_by,
                       @desc)
      @alpha_pagination_options = @grade_entry_form.alpha_paginate(
                                     all_students,
                                     @per_page,
                                     @students.total_pages)
      @alpha_category = @alpha_pagination_options.first
      session[:alpha_pagination_options] = @alpha_pagination_options
    else
      @alpha_pagination_options = session[:alpha_pagination_options]
      @alpha_category = params[:alpha_category]
    end
  end
  # Update a grade in the table
  def update_grade
    grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    @student_id = params[:student_id]
    @grade_entry_item_id = params[:grade_entry_item_id]
    updated_grade = params[:updated_grade]
    grade_entry_student =
        grade_entry_form.grade_entry_students.find_or_create_by_user_id(
           @student_id)
    @grade =
        grade_entry_student.grades.find_or_create_by_grade_entry_item_id(
           @grade_entry_item_id)
    @grade.grade = updated_grade
    @grade_saved = @grade.save
    @updated_student_total = grade_entry_form.calculate_total_mark(@student_id)
  end

  # For students
  def student_interface
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @student = current_user
  end

  # Release/unrelease the marks for all the students or for a subset of students
  def update_grade_entry_students
    return unless request.post?
    grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    errors = []
    grade_entry_students = []

    if params[:ap_select_full] == 'true'

      # Make sure we have a filter
      if params[:filter].blank?
        raise I18n.t('grade_entry_forms.grades.expected_filter')
      end

      # Find the appropriate students using this filter
      students = G_TABLE_PARAMS[:filters][params[:filter]][:proc].call()
      students.each do |student|
        grade_entry_students.push(grade_entry_form.grade_entry_students.find_or_create_by_user_id(student.id))
      end
    else
      # Particular students in the table were selected
      if params[:students].nil?
        errors.push(I18n.t('grade_entry_forms.grades.must_select_a_student'))
      else
        params[:students].each do |student_id|
          grade_entry_students.push(grade_entry_form.grade_entry_students.find_or_create_by_user_id(student_id))
        end
      end
    end

    # Releasing/unreleasing marks should be logged
    log_message = ""
    if !params[:release_results].nil?
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
               {:numGradeEntryStudentsChanged => numGradeEntryStudentsChanged})
      m_logger = MarkusLogger.instance
      m_logger.log(log_message)
    end
    flash[:errors] = errors

    redirect_to :action => 'grades', :id => params[:id]
  end

  # Download the grades for this grade entry form as a CSV file
  def csv_download
    grade_entry_form = GradeEntryForm.find(params[:id])
    send_data grade_entry_form.get_csv_grades_report,
         :disposition => 'attachment',
         :type => 'application/vnd.ms-excel',
         :filename => "#{grade_entry_form.short_identifier}_grades_report.csv"
  end

  # Upload the grades for this grade entry form using a CSV file
  def csv_upload
    @grade_entry_form = GradeEntryForm.find(params[:id])
    grades_file = params[:upload][:grades_file]
    encoding = params[:encoding]
    if request.post? && !grades_file.blank?
      begin
        GradeEntryForm.transaction do
          invalid_lines = []
          num_updates = GradeEntryForm.parse_csv(grades_file,
                                                 @grade_entry_form,
                                                 invalid_lines,
                                                 encoding)
          if !invalid_lines.empty?
            flash[:invalid_lines] = invalid_lines
            flash[:error] = I18n.t('csv_invalid_lines')
          end
          if num_updates > 0
            flash[:upload_notice] = I18n.t(
                                 'grade_entry_forms.csv.upload_success',
                                 :num_updates => num_updates)
          end
        end
      end
    end

    redirect_to :action => 'grades', :id => @grade_entry_form.id
  end

end
