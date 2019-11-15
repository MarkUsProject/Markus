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
    elsif status[:error_message].present?
      flash_progress_message(status)
      flash_message(:error, status[:error_message])
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
    current_status = status[:job_class].show_status(status)
    flash_message(:notice, current_status) unless current_status.nil?
  end
end
