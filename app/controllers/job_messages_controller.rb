class JobMessagesController < ApplicationController
  before_action { authorize! }

  def get
    status = ActiveJob::Status.get(params[:job_id])
    # yes handle this case
    if status.failed?
      flash_message(:error, t('poll_job.failed')) if status[:exception].blank? || status[:exception][:message].blank?
      session[:job_id] = nil
      # yes handle this case
    elsif status.completed?
      status[:progress] = status[:total]
      flash_message(:success, status[:job_class].completed_message(status))
      session[:job_id] = nil
    # Don't need to worry about this happening
    elsif status.read.empty?
      flash_message(:error, t('poll_job.failed'))
      session[:job_id] = nil
      render json: { code: '404', message: t('poll_job.not_enqueued') }, status: :not_found
      return
    end
    flash_job_messages(status)
    render json: status.read
  end

  private

  def flash_job_messages(status)
    # yes handle this case
    flash_message(:error, status[:exception][:message]) if status[:exception].present?
    # yes handle this case
    flash_message(:warning, status[:warning_message]) if status[:warning_message].present?
    current_status = status[:job_class]&.show_status(status)
    if current_status.nil? || session[:job_id].nil?
      # why are we hiding the notice flashes, we haven't flashed a notice up to this point
      hide_flash :notice
    else
      # yes handle this case
      status.queued? ? flash_message(:notice, t('poll_job.queued')) : flash_message(:notice, current_status)
    end
  end

  protected

  def implicit_authorization_target
    OpenStruct.new policy_class: JobMessagePolicy
  end

  def parent_params
    []
  end

  # Job messages are allowed while switching courses
  def check_course_switch; end
end
