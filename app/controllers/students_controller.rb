class StudentsController < ApplicationController
  before_action :authorize_only_for_admin

  layout 'assignment_content'

  responders :flash, :collection

  def note_message
    @student = Student.find(params[:id])
    if params[:success]
      flash_message(:success, I18n.t('notes.create.success'))
    else
      flash_message(:error, I18n.t('notes.error'))
    end
  end

  def index
    respond_to do |format|
      format.html
      format.json {
        student_data = Student.includes(:grace_period_deductions, :section).map do |s|
          {
            _id: s.id,
            user_name: s.user_name,
            first_name: s.first_name,
            last_name: s.last_name,
            email: s.email,
            id_number: s.id_number,
            hidden: s.hidden,
            section: s.section_id,
            grace_credits: s.grace_credits,
            remaining_grace_credits: s.remaining_grace_credits
          }
        end
        sections = Hash[Section.all.map { |section| [section.id, section.name] }]
        render json: {
          students: student_data,
          sections: sections
        }
      }
    end
  end

  def edit
    @user = Student.find_by_id(params[:id])
    @sections = Section.order(:name)
  end

  def update
    @user = Student.find(params[:id])
    @user.update(user_params)
    @sections = Section.order(:name)
    respond_with(@user)
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
                                   params[:grace_credits])
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
    @user = Student.create(user_params)
    @sections = Section.order(:name)
    respond_with(@user)
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
          info = [student.user_name, student.last_name, student.first_name, student.id_number, student.email]
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
      result = User.upload_user_list(Student, params[:userlist].read, params[:encoding])
      unless result[:invalid_lines].blank?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].blank?
        flash_message(:success, result[:valid_lines])
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
                                 :email,
                                 :id_number,
                                 :grace_credits,
                                 :section_id)
  end

  def flash_interpolation_options
    { resource_name: @user.user_name }
  end
end
