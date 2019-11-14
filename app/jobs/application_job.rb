class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status

  def self.on_complete_js(_status)
    '() => {}'
  end

  def self.show_status(status)
    I18n.t('poll_job.working_message', progress: status[:progress], total: status[:total])
  end

  before_enqueue do |_job|
    self.status.update(job_class: self.class)
  end
end
