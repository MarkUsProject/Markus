class UncollectSubmissions < ApplicationJob

  queue_as MarkusConfigurator.markus_job_uncollect_submissions_queue_name

  def self.on_complete_js(status)
    'window.submissionTable.wrapped.fetchData'
  end

  def self.show_status(status)
    I18n.t('poll_job.uncollect_submissions_job')
  end

  def perform(assignment)
    # TODO: implement this.
  end
end
