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
      flash_now(:success, "#{status[:progress]} out of #{status[:total]}")
    else
      flash_now(:success, "#{status.status}")
    end
    render json: status.read
  end
end
