class AutotestResetUrlJob < ApplicationJob
  include AutomatedTestsHelper::AutotestApi

  def self.show_status(_status); end

  def should_run?
    course, url, _ = self.arguments
    current_url = course.autotest_setting&.url
    (current_url.nil? && url.present?) || (current_url != url&.strip)
  end

  def self.js_set_url(url)
    %(
      () => {
        if (!document.getElementById('course_autotest_url')) {
          window.addEventListener("load", () => {
           document.getElementById('course_autotest_url').value='#{url}'
          })
        } else {
           document.getElementById('course_autotest_url').value='#{url}'
        }
      }
    )
  end

  def self.on_success_js(status)
    self.js_set_url(status[:url] || '')
  end

  def self.on_failure_js(status)
    self.js_set_url(status[:prev_url] || '')
  end

  around_perform do |job, block|
    block.call if job.should_run?
  end

  around_enqueue do |job, block|
    job.status.update(url: job.arguments.second)
    job.status.update(prev_url: job.arguments.first.autotest_setting&.url)
    block.call if job.should_run?
  end

  def perform(course, url, host_with_port)
    if url.blank?
      if course.update(autotest_setting_id: nil)
        AssignmentProperties.where(assessment_id: course.assignments.ids).update_all(remote_autotest_settings_id: nil)
      end
    else
      autotest_setting = AutotestSetting.find_or_create_by(url: url.strip)
      errors = []
      if autotest_setting.id != course.autotest_setting&.id
        course.update!(autotest_setting_id: autotest_setting.id)
        AssignmentProperties.where(assessment_id: course.assignments.ids).update_all(remote_autotest_settings_id: nil)
        course.assignments
              .joins(:assignment_properties)
              .where.not('assignment_properties.autotest_settings': nil)
              .each do |assignment|
          AutotestSpecsJob.perform_now(host_with_port, assignment)
        rescue StandardError => e
          errors << I18n.t('automated_tests.job_messages.resetting_test_settings_error',
                           short_identifier: assignment.short_identifier, error: e.to_s)
          status.update(error_message: msg)
        end
        raise errors.join("\n") unless errors.empty?
      end
    end
  end
end
