class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status
  include Bullet::ActiveJob if Rails.env.development?

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

  # Declares that this job accesses many repositories, so that resources held by closed repositories are
  # released periodically while it runs (see Repository::AbstractRepository.bulk_access).
  def self.accesses_repositories_in_bulk
    around_perform do |_job, block|
      Repository.get_class.bulk_access(&block)
    end
  end

  before_enqueue do |job|
    self.status.update(job_class: job.class)
  end

  def self.queue_name
    Settings.queues[self.name.underscore] || Settings.queues.default
  end
end
