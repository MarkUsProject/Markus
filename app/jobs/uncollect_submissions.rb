# Need to create a resque worker to listen to default queue to perform the job
# VVERBOSE=1 QUEUE=default rake environment resque:work
class UncollectSubmissions < ActiveJob::Base
  queue_as :default

  before_enqueue do |_job|
    job_messenger = JobMessenger.create(job_id: job_id, status: :queued)
    PopulateCache.populate_for_job(job_messenger, job_id)
  end

  def perform(assignment)
    begin
      # Update our messenger and populate the cache with its new status
      job_messenger = JobMessenger.where(job_id: job_id).first
      job_messenger.update_attributes(status: :running)
      PopulateCache.populate_for_job(job_messenger, job_id)
      submissions_collector = SubmissionCollector.instance
      submissions_collector.uncollect_submissions(assignment)
    rescue => e
      Rails.logger.error e.message
      job_messenger.update_attributes(status: failed, message: e.message)
      PopulateCache.populate_for_job(job_messenger, job_id)
      raise e
    end
    job_messenger.update_attributes(status: :succeeded)
    PopulateCache.populate_for_job(job_messenger, job_id)
  end
end
