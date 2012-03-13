class StudentsController < ApplicationController
  include UsersHelper
  before_filter    :authorize_only_for_admin

  def note_message
    @student = Student.find(params[:id])
    if params[:success]
      flash[:success] = I18n.t('notes.create.success')
    else
      flash[:error] = I18n.t('notes.error')
    end
  end

  def index
    @students = Student.find(:all, :order => "user_name")
    @sections = Section.find(:all, :order => "name")
  end

  def populate
    @students_data = Student.find(:all,
                                  :order => "user_name",
                                  :include => [:section,
                                               :grace_period_deductions])
    # construct_table_rows defined in UsersHelper
    @students = construct_table_rows(@students_data)
  end

  def edit
    @user = Student.find_by_id(params[:id])
    @sections = Section.find(:all, :order => "name")
  end

  def update
    @user = Student.find_by_id(params[:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if !@user.update_attributes(attrs)
      flash[:error] = I18n.t("students.update.error")
      @sections = Section.find(:all, :order => "name")
      render :edit
    else
      flash[:success] = I18n.t("students.update.success",
                               :user_name => @user.user_name)
      redirect_to :action => 'index'
    end
  end

  def bulk_modify
    student_ids = params[:student_ids]
    begin
      if student_ids.nil? || student_ids.empty?
        raise I18n.t("students.no_students_selected")
      end
      case params[:bulk_action]
        when "hide"
          Student.hide_students(student_ids)
          @students = construct_table_rows(Student.find(student_ids))
          return
        when "unhide"
          Student.unhide_students(student_ids)
          @students = construct_table_rows(Student.find(student_ids))
          return
        when "give_grace_credits"
          Student.give_grace_credits(student_ids, params[:number_of_grace_credits])
          @students = construct_table_rows(Student.find(student_ids))
          return
        when "add_section"
          Student.update_section(student_ids, params[:section])
          @students = construct_table_rows(Student.find(student_ids))
      end
    rescue RuntimeError => e
      @error = e.message
      render :display_error
    end
  end

  def new
    @user = Student.new(params[:user])
    @sections = Section.find(:all, :order => "name")
  end

  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Student.new(params[:user])
    if @user.save
      flash[:success] = I18n.t("students.create.success",
                               :user_name => @user.user_name)
      redirect_to :action => 'index' # Redirect
    else
      @sections = Section.find(:all, :order => "name")
      flash[:error] = I18n.t('students.create.error')
      render :new
    end
  end

  # dummy action for remote rjs calls
  # triggered by clicking on the "add a new section" link in the new student page
  # please keep.
  def add_new_section
     @section = Section.new
  end

  #downloads users with the given role as a csv list
  def download_student_list
    #find all the users
    students = Student.find(:all, :order => "user_name")
    case params[:format]
    when "csv"
      output = User.generate_csv_list(students)
      format = "text/csv"
    when "xml"
      output = students.to_xml
      format = "text/xml"
    else
      # Raise exception?
      output = students.to_xml
      format = "text/xml"
    end
    send_data(output, :type => format, :disposition => "inline")
  end

  def upload_student_list
    if request.post? && !params[:userlist].blank?
      begin
        result = User.upload_user_list(Student, params[:userlist], params[:encoding])
        if result[:invalid_lines].size > 0
          flash[:invalid_lines] = result[:invalid_lines]
        end
        flash[:success] = result[:upload_notice]
      rescue RuntimeError
        flash[:upload_notice] = I18n.t('csv_valid_format')
      end

    end
    redirect_to :action => 'index'
  end

  def delete_grace_period_deduction
    grace_deduction = GracePeriodDeduction.find(params[:id])
    student_id = grace_deduction.membership.user.id
    grace_deduction.destroy
    student = Student.find(student_id)
    @grace_period_deductions = student.grace_period_deductions
  end

end
