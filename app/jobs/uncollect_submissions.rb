class UncollectSubmissions < ApplicationJob

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
