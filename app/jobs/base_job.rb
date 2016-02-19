class BaseJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.config.active_job.default_url_options
  end
end