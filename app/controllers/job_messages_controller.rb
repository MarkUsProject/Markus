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
    if status.working?
      if status[:job_class]
        flash_now(:notice, status[:job_class].show_status(status))
      else #default x out of y message
        flash_now(:notice, t('poll_job.working_message', progress: status[:progress], total: status[:total]))
      end
    else
      if status.queued?
        flash_now(:notice, t('poll_job.queued'))
      elsif status[:job_class]&.respond_to?(:show_error_message)
        error_message = status[:job_class].show_error_message(status)
        if error_message.present?
          flash_now(:error, status[:job_class].show_error_message(status))
        end
      elsif status.completed?
        flash_now(:success, t('poll_job.completed'))
      else
        flash_now(:error, t('poll_job.failed'))
      end
      if status.completed? || status.failed?
        session[:job_id] = nil
      end
    end
    render json: status.read
  end
end
