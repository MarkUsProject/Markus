class AutotestResultsJob < ApplicationJob
  include AutomatedTestsHelper::AutotestApi

  around_enqueue do |job, block|
    redis = Redis::Namespace.new(Rails.root.to_s)
    block.call if redis.setnx('autotest_results', job.job_id)
    redis.expire('autotest_results', 300) # expire the key just in case
  end

  around_perform do |job, block|
    self.class.set(wait: 1.minute).perform_later(*job.arguments) if block.call
  rescue StandardError
    # if the job failed, retry 3 times
    assignment_id, kwargs = job.arguments
    self.class.set(wait: 1.minute).perform_later(assignment_id, _retry: kwargs[:_retry] - 1) if kwargs[:_retry] > 0
  end

  def self.show_status(_status); end

  def perform(assignment_id, _retry: 3)
    outstanding_results = false
    test_runs = TestRun.where(status: :in_progress)
    assignment = Assignment.find(assignment_id)
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
  ensure
    redis = Redis::Namespace.new(Rails.root.to_s)
    if redis.get('autotest_results') == self.job_id
      redis.del('autotest_results')
    end
    outstanding_results
  end
end
