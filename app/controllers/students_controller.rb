class StudentsController < ApplicationController
  before_action do |_|
    authorize! with: UserPolicy
  end

  layout 'assignment_content'

  responders :flash, :collection

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

  def download
    students = Student.order(:user_name).includes(:section)
    case params[:format]
      when 'csv'
        output = MarkusCsv.generate(students) do |student|
          Student::CSV_UPLOAD_ORDER.map do |field|
            if field == :section_name
              student.section&.name
            else
              student.send(field)
            end
          end
        end
        format = 'text/csv'
      else
        output = []
        students.all.each do |student|
          output.push(user_name: student.user_name,
                      last_name: student.last_name,
                      first_name: student.first_name,
                      email: student.email,
                      id_number: student.id_number,
                      section_name: student.section&.name)
        end
        output = output.to_yaml
        format = 'text/yaml'
    end
    send_data(output,
              type: format,
              filename: "student_list.#{params[:format]}",
              disposition: 'attachment')
  end

  def upload
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        result = User.upload_user_list(Student, params[:upload_file].read, params[:encoding])
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      end
    end
    redirect_to action: 'index'
  end

  def delete_grace_period_deduction
    student = Student.find(params[:id])
    grace_deduction = student.grace_period_deductions.find(params[:deduction_id])
    grace_deduction.destroy
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
    { resource_name: @user.user_name.blank? ? @user.model_name.human : @user.user_name,
      errors: @user.errors.full_messages.join('; ')}
  end
end
