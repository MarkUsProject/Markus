class StudentsController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json do
        student_data = current_course.students.includes(:grace_period_deductions, :section, :user).map do |s|
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
        sections = current_course.sections.pluck(:id, :name).to_h
        render json: {
          students: student_data,
          sections: sections,
          counts: {
            all: current_course.students.size,
            active: current_course.students.active.size,
            inactive: current_course.students.inactive.size
          }
        }
      end
    end
  end

  def edit
    @role = record
    @sections = current_course.sections.order(:name)
  end

  def update
    @role = record
    @role.update(role_params)
    @sections = current_course.sections.order(:name)
    respond_with @role, location: course_students_path(@current_course)
  end

  def bulk_modify
    student_ids = params[:student_ids].map(&:to_i)&.intersection(current_course.students.ids)
    begin
      if student_ids.blank?
        raise I18n.t('students.no_students_selected')
      end
      case params[:bulk_action]
      when 'hide'
        Student.hide_students(student_ids) if allowed_to?(:manage_role_status?)
      when 'unhide'
        Student.unhide_students(student_ids) if allowed_to?(:manage_role_status?)
      when 'give_grace_credits'
        Student.give_grace_credits(student_ids,
                                   params[:grace_credits])
      when 'update_section'
        Student.update_section(student_ids, params[:section])
      end
      head :ok
    rescue RuntimeError => e
      flash_now(:error, e.message)
      head :internal_server_error
    end
  end

  def new
    @role = current_course.students.new
    @sections = current_course.sections.order(:name)
  end

  def create
    user = EndUser.find_by(user_name: params[:role][:end_user][:user_name])
    @role = current_course.students.create(user: user, **role_params)
    @sections = current_course.sections.order(:name)
    respond_with @role, location: course_students_path(current_course)
  end

  # dummy action for remote rjs calls
  # triggered by clicking on the "add a new section" link in the new student page
  # please keep.
  def add_new_section
    @section = Section.new
  end

  def download
    case params[:format]
    when 'csv'
      output = current_course.export_student_data_csv
      format = 'text/csv'
    else
      output = current_course.export_student_data_yml
      format = 'text/yaml'
    end
    send_data(output, type: format, filename: "student_list.#{params[:format]}", disposition: 'attachment')
  end

  def upload
    begin
      data = process_file_upload(['.csv'])
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      @current_job = UploadRolesJob.perform_later(Student,
                                                  current_course,
                                                  data[:contents],
                                                  data[:encoding])
      session[:job_id] = @current_job.job_id
    end
    redirect_to action: 'index'
  end

  def delete_grace_period_deduction
    student = record
    grace_deduction = student.grace_period_deductions.find(params[:deduction_id])
    grace_deduction.destroy
    @grace_period_deductions = student.grace_period_deductions
  end

  def settings; end

  def update_settings
    role = current_role
    role.update!(settings_params)
    flash_message(:success, t('users.verify_settings_update'))
    redirect_to action: 'settings'
  end

  def destroy
    @role = record
    begin
      @role.destroy!
    rescue ActiveRecord::DeleteRestrictionError => e
      flash_message(:error, I18n.t('flash.students.destroy.restricted', user_name: @role.user_name, message: e.message))
      head :conflict
    rescue ActiveRecord::RecordNotDestroyed => e
      flash_message(:error, I18n.t('flash.students.destroy.error', user_name: @role.user_name, message: e.message))
      head :bad_request
    else
      flash_now(:success, I18n.t('flash.students.destroy.success', user_name: @role.user_name))
      head :no_content
    end
  end

  private

  def role_params
    keys = [:grace_credits, :section_id]
    keys << :hidden if allowed_to?(:manage_role_status?)
    params.require(:role).permit(*keys)
  end

  def settings_params
    params.require(:role).permit(:receives_invite_emails, :receives_results_emails)
  end

  def flash_interpolation_options
    { resource_name: @role.user&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ') }
  end
end
