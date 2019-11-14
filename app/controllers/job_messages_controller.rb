class JobMessagesController < ApplicationController
  before_action :authorize_only_for_admin

  def show
   @job_message = Rails.cache.fetch(params[:job_id])
   respond_to do |format|
     format.json { render 'job_messages/show'}
   end
  end

  def get
    status = ActiveJob::Status.get(params[:job_id])
    if status.queued?
      flash_message(:notice, t('poll_job.queued'))
    elsif status.working?
      flash_progress_message(status)
    elsif status[:job_class]&.show_error_message(status).present?
      flash_progress_message(status)
      flash_message(:error, status[:job_class].show_error_message(status))
    elsif status.completed?
      status[:progress] = status[:total]
      flash_progress_message(status)
      flash_message(:success, t('poll_job.completed'))
    else
      flash_message(:error, t('poll_job.failed'))
    end
    if status.completed? || status.failed?
      session[:job_id] = nil
    end
    render json: status.read
  end

  private

  def flash_progress_message(status)
    if status[:job_class]
      flash_message(:notice, status[:job_class].show_status(status))
    else # default x out of y message
      flash_message(:notice, t('poll_job.working_message', progress: status[:progress], total: status[:total]))
    end
  end
end
