class UncollectSubmissions < ApplicationJob

  queue_as MarkusConfigurator.markus_job_uncollect_submissions_queue_name

  def self.on_complete_js(status)
    'window.submissionTable.wrapped.fetchData'
  end

  def self.show_status(status)
    I18n.t('poll_job.uncollect_submissions_job')
  end

  before_enqueue do |job|
    status.update(job_class: self.class)
  end

  def perform(assignment)
    begin
      submissions_collector = SubmissionCollector.instance
      submissions_collector.uncollect_submissions(assignment)
    rescue => e
      Rails.logger.error e.message
    end
  end
end
