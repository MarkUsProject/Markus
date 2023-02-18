class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status

  queue_as queue_name

  def self.on_complete_js(_status)
    '() => {}'
  end

  def self.on_success_js(_status)
    '() => {}'
  end

  def self.on_failure_js(_status)
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

  def self.queue_name
    Settings.queues[self.name.underscore] || Settings.queues.default
  end
end
