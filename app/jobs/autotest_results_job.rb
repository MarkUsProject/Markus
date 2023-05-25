# Checks the status of in_progress test runs and gets the results
# of completed tests
class AutotestResultsJob < AutotestJob
  around_enqueue do |job, block|
    # Interface with redis keyspace provided
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    # Set key if key does not exist, also enqueue if the key was set and dequeue if the key was not set
    block.call if redis.setnx('autotest_results', job.job_id)
    redis.expire('autotest_results', 300) # expire the key just in case
  end

  around_perform do |job, block|
    # if there are outstanding results
    self.class.set(wait: 5.seconds).perform_later(*job.arguments) if block.call
  rescue StandardError
    # if the job failed, retry 3 times
    kwargs = job.arguments.first || { _retry: 3 }
    self.class.perform_later(_retry: kwargs[:_retry] - 1) if kwargs[:_retry] > 0
    raise
  end

  def self.show_status(_status); end

  def perform(_retry: 3)
    # define outstanding_results variable
    outstanding_results = false
    # get the ids of the in progress tests (according to the database)
    ids = Assignment.joins(groupings: :test_runs)
                    .where('test_runs.status': TestRun.statuses[:in_progress])
                    .pluck('assessments.id', 'test_runs.id')
                    .group_by(&:first)
                    .transform_values { |v| v.map(&:second) }
    # for each of the in progress tests...
    ids.each do |assignment_id, test_run_ids|
      assignment = Assignment.find(assignment_id)
      test_runs = TestRun.where(id: test_run_ids)
      # loop through the statuses
      statuses(assignment, test_runs).each do |autotest_test_id, status|
        # statuses from rq: https://python-rq.org/docs/jobs/#retrieving-a-job-from-redis
        status = 'not_found' if status.nil?
        if %(started queued deferred).include? status
          outstanding_results = true
        else
          test_run = test_runs.find_by(autotest_test_id: autotest_test_id)
          if %(finished failed).include? status
            results(test_run.grouping.assignment, test_run) unless test_run.nil?
          else
            test_run&.failure(status)
          end
          if !test_run.nil? && test_run.role.student?
            StudentTestsChannel.broadcast_to(test_run.role.user, body: 'sent')
          end
        end
      end
    end
    # return whether or not there are outstanding results
    outstanding_results
  ensure
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    if redis.get('autotest_results') == self.job_id
      redis.del('autotest_results')
    end
  end
end
