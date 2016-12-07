class StudentsController < ApplicationController
  include UsersHelper
  include StudentsHelper
  before_filter    :authorize_only_for_admin

  def note_message
    @student = Student.find(params[:id])
    if params[:success]
      flash_message(:success, I18n.t('notes.create.success'))
    else
      flash_message(:error, I18n.t('notes.error'))
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
      flash_message(:success, I18n.t('students.update.success',
                                     user_name: @user.user_name))
      redirect_to action: 'index'
    else
      flash_message(:error, I18n.t('students.update.error'))
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
      flash_now(:error, e.message)
      head 500
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
      flash_message(:success, I18n.t('students.create.success',
                                     user_name: @user.user_name))
      redirect_to action: 'index' # Redirect
    else
      @sections = Section.order(:name)
      flash_message(:error, I18n.t('students.create.error'))
      render :new
    end
  end

  # dummy action for remote rjs calls
  # triggered by clicking on the "add a new section" link in the new student page
  # please keep.
  def add_new_section
     @section = Section.new
  end

  # downloads students as a csv list
  def download_student_list
    students = Student.order(:user_name).includes(:section)
    case params[:format]
      when 'csv'
        output = MarkusCSV.generate(students) do |student|
          info = [student.user_name, student.last_name, student.first_name]
          unless student.section.nil?
            info << student.section.name
          end
          info
        end
        format = 'text/csv'
      when 'xml'
        output = students.to_xml
        format = 'text/xml'
      else
        # Raise exception?
        output = students.to_xml
        format = 'text/xml'
    end
    send_data(output, type: format, disposition: 'attachment')
  end

  def upload_student_list
    if params[:userlist]
      User.transaction do
        processed_users = []
        result = MarkusCSV.parse(params[:userlist],
                                 skip_blanks: true,
                                 row_sep: :auto,
                                 encoding: params[:encoding]) do |row|
          next if CSV.generate_line(row).strip.empty?
          raise CSVInvalidLineError if processed_users.include?(row[0])
          raise CSVInvalidLineError if User.add_user(Student, row).nil?
          processed_users.push(row[0])
        end
        unless result[:invalid_lines].empty?
          flash_message(:error, result[:invalid_lines])
        end
        unless result[:valid_lines].empty?
          flash_message(:success, result[:valid_lines])
        end
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
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
