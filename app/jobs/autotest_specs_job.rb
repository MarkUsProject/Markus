# Job to send test settings to the autotester
class AutotestSpecsJob < AutotestJob
  def self.show_status(_status)
    I18n.t('poll_job.autotest_specs_job')
  end

  def self.on_complete_js(status)
    %(
      window.addEventListener("load", () => {
        window.autotestManagerComponent.setState({formData: JSON.parse('#{status[:test_specs].to_json}')});
      })
    )
  end

  before_enqueue do |job|
    self.status.update(test_specs: job.arguments[2])
  end

  def perform(host_with_port, assignment, test_specs)
    ApplicationRecord.transaction do
      update_test_groups_from_specs(assignment, test_specs)
      update_settings(assignment, host_with_port)
    end
  end
end
