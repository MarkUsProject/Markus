class UncollectSubmissions < ApplicationJob
  def self.on_complete_js(_status)
    'window.submissionTable.current.fetchData'
  end

  def self.show_status(_status)
    I18n.t('poll_job.uncollect_submissions_job')
  end

  def perform(assignment)
    # TODO: implement this.
  end
end
