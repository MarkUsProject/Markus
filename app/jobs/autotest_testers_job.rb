class AutotestTestersJob < ApplicationJob
  include AutomatedTestsHelper::AutotestApi

  def self.show_status(_status); end

  def perform
    schema
  end
end
