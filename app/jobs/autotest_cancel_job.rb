# Job to cancel autotest tests
class AutotestCancelJob < AutotestJob
  def self.on_complete_js(_status)
    'window.batchTestRunTable.current.fetchData'
  end

  def self.show_status(_status); end

  def perform(assignment_id, test_run_ids)
    cancel_tests(Assignment.find(assignment_id), TestRun.where(id: test_run_ids))
  end
end
