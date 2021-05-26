# Job to send test settings to the autotester
class AutotestSpecsJob < AutotestJob
  def self.show_status(_status)
    I18n.t('poll_job.autotest_specs_job')
  end

  def perform(host_with_port, assignment)
    update_settings(assignment, host_with_port)
  end
end
