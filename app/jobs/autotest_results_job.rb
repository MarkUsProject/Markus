class AutotestResultsJob < ApplicationJob
  include AutomatedTestsHelper::AutotestApi

  # TODO: one job at a time. try to enqueue a new one after every test run is enqueued
  #       redo every minute (burst mode) until all in_progress tests are finished.
  #       on an unexpected failure, retry 3 times before giving up
  #
  around_perform do |job, block|
    self.class.set(wait: 1.minute).perform_later(*job.arguments) if block.call
  rescue StandardError
    # if the job failed, retry only once
    self.class.set(wait: 1.minute).perform_later(*job.arguments, _retry: false)
  end

  def self.show_status(_status); end

  def perform(assignment_id, _retry: 3)
    test_runs = TestRun.where(status: :in_progress)
    assignment = Assignment.find(assignment_id)
    outstanding_results = false
    statuses(assignment, test_runs).each do |autotest_test_id, status|
      # statuses from rq: https://python-rq.org/docs/jobs/#retrieving-a-job-from-redis
      if %[started queued deferred].include? status
        outstanding_results = true
      else
        test_run = TestRun.where(autotest_test_id: autotest_test_id).first
        if %[finished failed].include? status
          results(assignment, test_run) unless test_run.nil?
        else
          test_run&.failure(status)
        end
      end
    end
    outstanding_results && _retry > 0
  end
end
