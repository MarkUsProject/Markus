class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status

  def self.on_complete_js(_status)
    '() => {}'
  end

  def self.show_status(status)
    I18n.t('poll_job.working_message', progress: status[:progress], total: status[:total])
  end

  def self.completed_message(_status)
    I18n.t('poll_job.completed')
  end

  before_enqueue do |job|
    self.status.update(job_class: job.class)
  end

  rescue_from(StandardError) do |e|
    self.status.update(error_message: e.to_s)
    self.status.update(status: :failed)
    raise
  end
end
