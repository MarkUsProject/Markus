class TestRun < ApplicationRecord
  enum status: { in_progress: 0, complete: 1, cancelled: 2, failed: 3 }
  has_many :test_group_results, dependent: :destroy
  has_many :feedback_files, through: :test_group_results
  belongs_to :test_batch, optional: true
  belongs_to :submission, optional: true
  belongs_to :grouping
  belongs_to :user

  ASSIGNMENTS_DIR = File.join(Settings.autotest.client_dir, 'assignments').freeze
  SPECS_FILE = 'specs.json'.freeze
  FILES_DIR = 'files'.freeze

  def cancel
    self.update(status: :cancelled) if self.in_progress?
  end

  def failure(problems)
    self.update(status: :failed, problems: problems) if self.in_progress?
  end

  def update_results!(results)
    if results['status'] == 'failed'
      failure(results['error'])
    else
      self.update!(status: :complete, problems: results['error'])
      results['test_groups'].each do |result|
        error = nil
        ApplicationRecord.transaction do
          test_group_result = create_test_group_result(result)
          result['tests'].each do |test|
            test_group_result.test_results.create(
              name: test['name'],
              status: test['status'],
              marks_earned: test['marks_earned'],
              output: test['output'].gsub("\x00", '\\u0000'),
              marks_total: test['marks_total'],
              time: test['time']
            )
          end
        rescue StandardError => e
          error = e
          raise ActiveRecord::Rollback
        end
        create_test_group_result(result, error: error) unless error.nil?
      end
    end
  end

  def self.all_test_categories
    [Admin.name.downcase, Student.name.downcase]
  end

  private

  def extra_info_string(result)
    return nil if result['stderr'].blank? && result['malformed'].blank?

    extra = ''
    extra += I18n.t('automated_tests.results.extra_stderr', extra: result['stderr']) unless result['stderr'].blank?
    unless result['malformed'].blank?
      extra += I18n.t('automated_tests.results.extra_malformed', extra: result['malformed'])
    end
    extra
  end

  def error_type(result)
    return nil unless result['tests'].blank?
    return TestGroupResult::ERROR_TYPE[:timeout] if result['timeout']

    TestGroupResult::ERROR_TYPE[:no_results]
  end

  def create_test_group_result(result, error: nil)
    test_group_id = result.dig('extra_info', 'test_group_id')
    test_group = TestGroup.find_by(id: test_group_id)
    test_group.test_group_results.create(
      test_run_id: self.id,
      extra_info: error.nil? ? extra_info_string(result) : error.message,
      marks_total: error.nil? ? result['tests']&.map { |t| t['marks_total'] }&.sum || 0 : 0,
      marks_earned: error.nil? ? result['tests']&.map { |t| t['marks_earned'] }&.sum || 0 : 0,
      time: result['time'] || 0,
      error_type: error.nil? ? error_type(result) : TestGroupResult::ERROR_TYPE[:test_error]
    )
  end
end
