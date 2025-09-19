# Abstract super-class for all autotest jobs
class AutotestJob < ApplicationJob
  include AutomatedTestsHelper
  include AutomatedTestsHelper::AutotestApi

  around_perform do |job, block|
    block.call
  rescue LimitExceededException
    self.class.set(wait: 1.minute).perform_later(*job.arguments)
  end
end
