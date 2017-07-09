class JobMessagesController < ApplicationController
  before_filter  :authorize_only_for_admin

  def show
   @job_message = Rails.cache.fetch(params[:job_id])
   respond_to do |format|
     format.json { render 'job_messages/show'}
   end
  end

  def get
    status = ActiveJob::Status.get(params[:job_id])
    if status.working?
      flash_now(:success, t('poll_job.working_message', progress: status[:progress], total: status[:total]))
    else
      if status.queued?
        status_msg = t('poll_job.queued')
      elsif status.completed?
        status_msg = t('poll_job.completed')
      else
        status_msg = t('poll_job.failed')
      end
      flash_now(:success, status_msg)
      if status.completed?
        session[:job_id] = nil
      end
    end
    render json: status.read
  end
end
