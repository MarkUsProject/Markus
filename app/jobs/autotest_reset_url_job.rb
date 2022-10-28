class AutotestResetUrlJob < ApplicationJob
  include AutomatedTestsHelper::AutotestApi

  def self.show_status(_status)
    I18n.t('automated_tests.job_messages.resetting_test_settings')
  end

  def should_run?
    course, url, _, options = self.arguments
    current_url = course.autotest_setting&.url
    (current_url.nil? && url.present?) || (options&.[](:refresh) || current_url != url&.strip)
  end

  def self.js_update_form(url)
    %(
      () => {
        if (!document.getElementById('course_autotest_url')) {
          window.addEventListener("load", () => {
           document.getElementById('course_autotest_url').value='#{url}'
          })
        } else {
           document.getElementById('course_autotest_url').value='#{url}'
        }
        if (!document.getElementById('manage-connection')) {
          window.addEventListener("load", () => {
           document.getElementById('manage-connection').className='#{url.empty? ? 'no-display' : ''}'
          })
        } else {
           document.getElementById('manage-connection').className='#{url.empty? ? 'no-display' : ''}'
        }
      }
    )
  end

  def self.on_success_js(status)
    self.js_update_form(status[:url] || '')
  end

  def self.on_failure_js(status)
    self.js_update_form(status[:prev_url] || '')
  end

  around_perform do |job, block|
    block.call if job.should_run?
  end

  around_enqueue do |job, block|
    job.status.update(url: job.arguments.second)
    job.status.update(prev_url: job.arguments.first.autotest_setting&.url)
    block.call if job.should_run?
  end

  def perform(course, url, host_with_port, refresh: false)
    if url.blank?
      course.update!(autotest_setting_id: nil)
      TestRun.where(status: :in_progress).update_all(status: :cancelled)
      TestRun.update_all(autotest_test_id: nil)
      AssignmentProperties.where(assessment_id: course.assignments.ids).update_all(remote_autotest_settings_id: nil)
    else
      autotest_setting = AutotestSetting.find_or_create_by(url: url.strip)
      update_credentials(autotest_setting) if refresh
      errors = []
      if refresh || autotest_setting.id != course.autotest_setting&.id
        course.update!(autotest_setting_id: autotest_setting.id)
        TestRun.where(status: :in_progress).update_all(status: :cancelled)
        TestRun.update_all(autotest_test_id: nil)
        AssignmentProperties.where(assessment_id: course.assignments.ids).update_all(remote_autotest_settings_id: nil)
        course.assignments
              .joins(:assignment_properties)
              .where.not('assignment_properties.autotest_settings': nil)
              .each do |assignment|
          AutotestSpecsJob.perform_now(host_with_port, assignment)
        rescue StandardError => e
          errors << I18n.t('automated_tests.job_messages.resetting_test_settings_error',
                           short_identifier: assignment.short_identifier, error: e.to_s)
          status.update(error_message: e.to_s)
        end
        raise errors.join("\n") unless errors.empty?
      end
    end
  end
end
