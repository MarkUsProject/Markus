class StudentsController < ApplicationController
  include UsersHelper
  include StudentsHelper
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
    @sections = Section.all
    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '" + I18n.t(:'user.section') + "',
        sortable: true
      },"
    end
  end

  def populate
    render json: get_students_table_info
  end

  def edit
    @user = Student.find_by_id(params[:id])
    @sections = Section.order(:name)
  end

  def update
    @user = Student.find_by_id(params[:id])
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(user_params)
      flash[:success] = I18n.t('students.update.success',
                               user_name: @user.user_name)
      redirect_to action: 'index'
    else
      flash[:error] = I18n.t('students.update.error')
      @sections = Section.order(:name)
      render :edit
    end
  end

  def bulk_modify
    student_ids = params[:student_ids]
    begin
      if student_ids.nil? || student_ids.empty?
        raise I18n.t('students.no_students_selected')
      end
      case params[:bulk_action]
      when 'hide'
        Student.hide_students(student_ids)
      when 'unhide'
        Student.unhide_students(student_ids)
      when 'give_grace_credits'
        Student.give_grace_credits(student_ids,
                                   params[:number_of_grace_credits])
      when 'update_section'
        Student.update_section(student_ids, params[:section])
      end
      head :ok
    rescue RuntimeError => e
      render text: e.message, status: 500
    end
  end

  def new
    @user = Student.new
    @sections = Section.order(:name)
  end

  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Student.new(user_params)
    if @user.save
      flash[:success] = I18n.t('students.create.success',
                               user_name: @user.user_name)
      redirect_to action: 'index' # Redirect
    else
      @sections = Section.order(:name)
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
    students = Student.order(:user_name)
    case params[:format]
    when 'csv'
      output = User.generate_csv_list(students)
      format = 'text/csv'
    when 'xml'
      output = students.to_xml
      format = 'text/xml'
    else
      # Raise exception?
      output = students.to_xml
      format = 'text/xml'
    end
    send_data(output, type: format, disposition: 'inline')
  end

  def upload_student_list
    if request.post? && !params[:userlist].blank?
      begin
        result = User.upload_user_list(Student, params[:userlist], params[:encoding])
        if result[:invalid_lines].size > 0
          flash[:error] = I18n.t('csv_invalid_lines') +
            result[:invalid_lines].join(', ')
        end
        flash[:success] = result[:upload_notice]
      rescue CSV::MalformedCSVError
        flash[:error] = t('csv.upload.malformed_csv')
      rescue ArgumentError
        flash[:error] = I18n.t('csv.upload.non_text_file_with_csv_extension')
      rescue RuntimeError
        flash[:notice] = I18n.t('csv_valid_format')
      end

    end
    redirect_to action: 'index'
  end

  def delete_grace_period_deduction
    grace_deduction = GracePeriodDeduction.find(params[:deduction_id])
    student_id = grace_deduction.membership.user.id
    grace_deduction.destroy
    student = Student.find(student_id)
    @grace_period_deductions = student.grace_period_deductions
  end

  private

  def user_params
    params.require(:user).permit(:user_name,
                                 :last_name,
                                 :first_name,
                                 :grace_credits,
                                 :section_id)
  end
end
