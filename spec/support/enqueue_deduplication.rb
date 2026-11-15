# Some jobs (e.g. UpdateRepoPermissionsJob, AutotestResultsJob) skip enqueuing when a Redis lock
# (set with SETNX) is already held. Jobs are never performed in tests, so these locks are never released
# and leak across examples. Include this context when using have_enqueued_job with these jobs so that
# every call to perform_later results in an enqueued job.
shared_context 'without enqueue deduplication' do
  before { allow_any_instance_of(Redis::Namespace).to receive(:setnx).and_return(true) }
end
