class JobMessagesController < ApplicationController
  before_action :authorize_only_for_admin

  def get
    status = ActiveJob::Status.get(params[:job_id])
    if status.failed?
      flash_message(:error, t('poll_job.failed')) unless status[:error_message].present?
      session[:job_id] = nil
    elsif status.completed?
      status[:progress] = status[:total]
      flash_message(:success, t('poll_job.completed'))
      session[:job_id] = nil
    elsif status.read.empty?
      flash_message(:error, t('poll_job.failed'))
      session[:job_id] = nil
      render 'shared/http_status', locals: { code: '404', message: 'No background job was enqueued' }, status: 404
      return
    end
    flash_job_messages(status)
    render json: status.read
  end

  private

  def flash_job_messages(status)
    flash_message(:error, status[:error_message]) if status[:error_message].present?
    current_status = status[:job_class]&.show_status(status)
    return if current_status.nil?

    status.queued? ? flash_message(:notice, t('poll_job.queued')) : flash_message(:notice, current_status)
  end
end
