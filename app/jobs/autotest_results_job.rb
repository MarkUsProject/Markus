# Checks the status of in_progress test runs and gets the results
# of completed tests
class AutotestResultsJob < AutotestJob
  around_enqueue do |job, block|
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    block.call if redis.setnx('autotest_results', job.job_id)
    redis.expire('autotest_results', 300) # expire the key just in case
  end

  around_perform do |job, block|
    self.class.set(wait: 5.seconds).perform_later(*job.arguments) if block.call
  rescue StandardError
    # if the job failed, retry 3 times
    kwargs = job.arguments.first || { _retry: 3 }
    self.class.perform_later(_retry: kwargs[:_retry] - 1) if kwargs[:_retry] > 0
    raise
  end

  def self.show_status(_status); end

  def perform(_retry: 3)
    outstanding_results = false
    ids = Assignment.joins(groupings: :test_runs)
                    .where('test_runs.status': TestRun.statuses[:in_progress])
                    .pluck('assessments.id', 'test_runs.id')
                    .group_by(&:first)
                    .transform_values { |v| v.map(&:second) }

    # Map users to the ids of assignments with updated results from their test runs
    updated_assignment_batch_runs = Hash.new { |h, k| h[k] = [] }

    ids.each do |assignment_id, test_run_ids|
      assignment = Assignment.find(assignment_id)
      test_runs = TestRun.where(id: test_run_ids)
      updated_users = []
      statuses(assignment, test_runs).each do |autotest_test_id, test_run_status|
        # statuses from rq: https://python-rq.org/docs/jobs/#retrieving-a-job-from-redis
        test_run_status = 'not_found' if test_run_status.nil?
        if %(started queued deferred).include? test_run_status
          outstanding_results = true
        else
          test_run = test_runs.find_by(autotest_test_id: autotest_test_id)
          if %(finished failed).include? test_run_status
            results(test_run.grouping.assignment, test_run) unless test_run.nil?
          else
            test_run&.failure(test_run_status)
          end
          unless test_run.nil?
            if test_run.test_batch_id.nil?
              TestRunsChannel.broadcast_to(test_run.role.user, { status: 'completed', job_class: 'AutotestResultsJob' })
            else
              updated_users << test_run.role.user
            end
          end
        end
      end
      updated_users.each do |user|
        updated_assignment_batch_runs[user] << assignment_id
      end
    end

    updated_assignment_batch_runs.each do |user, assignment_ids|
      TestRunsChannel.broadcast_to(user,
                                   { status: 'completed',
                                     job_class: 'AutotestResultsJob',
                                     assignment_ids: assignment_ids,
                                     update_table: true })
    end
    outstanding_results
  ensure
    redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    if redis.get('autotest_results') == self.job_id
      redis.del('autotest_results')
    end
  end
end
