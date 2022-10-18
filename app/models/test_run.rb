class TestRun < ApplicationRecord
  enum status: { in_progress: 0, complete: 1, cancelled: 2, failed: 3 }
  has_many :test_group_results, dependent: :destroy
  has_many :feedback_files, through: :test_group_results
  belongs_to :test_batch, optional: true
  belongs_to :submission, optional: true
  belongs_to :grouping
  belongs_to :role

  has_one :course, through: :role

  validate :courses_should_match

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
        test_group_result = nil
        ApplicationRecord.transaction do
          test_group_result = create_test_group_result(result)
          result['tests'].each_with_index do |test, i|
            test_group_result.test_results.create!(
              name: test['name'],
              status: test['status'],
              marks_earned: test['marks_earned'],
              output: test['output'].gsub("\x00", '\\u0000'),
              marks_total: test['marks_total'],
              time: test['time'],
              position: i + 1
            )
          end
        rescue StandardError => e
          error = e
          raise ActiveRecord::Rollback
        end
        test_group_result = create_test_group_result(result, error: error) unless error.nil?
        create_annotations(result['annotations'])
        result['feedback']&.each { |feedback| create_feedback_file(feedback, test_group_result) }
      end
      self.submission&.set_autotest_marks
    end
  end

  def self.all_test_categories
    [Instructor.name.downcase, Student.name.downcase]
  end

  private

  def extra_info_string(result)
    return if result['stderr'].blank? && result['malformed'].blank?

    extra = ''
    extra += I18n.t('automated_tests.results.extra_stderr', extra: result['stderr']) if result['stderr'].present?
    if result['malformed'].present?
      extra += I18n.t('automated_tests.results.extra_malformed', extra: result['malformed'])
    end
    extra
  end

  def error_type(result)
    return if result['tests'].present?
    return TestGroupResult::ERROR_TYPE[:timeout] if result['timeout']

    TestGroupResult::ERROR_TYPE[:no_results]
  end

  def create_test_group_result(result, error: nil)
    test_group_id = result.dig('extra_info', 'test_group_id')
    test_group = TestGroup.find_by(id: test_group_id)
    test_group.test_group_results.create(
      test_run_id: self.id,
      extra_info: error.nil? ? extra_info_string(result) : error.message,
      marks_total: error.nil? ? result['tests']&.map { |t| t['marks_total'] }&.compact&.sum || 0 : 0,
      marks_earned: error.nil? ? result['tests']&.map { |t| t['marks_earned'] }&.compact&.sum || 0 : 0,
      time: result['time'] || 0,
      error_type: error.nil? ? error_type(result) : TestGroupResult::ERROR_TYPE[:test_error]
    )
  end

  def create_feedback_file(feedback_data, test_group_result)
    return if feedback_data.nil? || test_group_result.nil?

    test_group_result.feedback_files.create(
      filename: feedback_data['filename'],
      mime_type: feedback_data['mime_type'],
      file_content: unzip_file_data(feedback_data)
    )
  end

  def create_annotations(annotation_data)
    return if annotation_data.nil? || self.submission.nil? # don't create annotations for student run tests

    count = self.submission.annotations.count + 1
    annotation_data.each_with_index do |data, i|
      annotation_text = AnnotationText.create(
        content: data['content'],
        annotation_category_id: nil,
        creator_id: self.role.id,
        last_editor_id: self.role.id
      )
      result = self.submission.current_result
      TextAnnotation.create(
        line_start: data['line_start'],
        line_end: data['line_end'],
        column_start: data['column_start'],
        column_end: data['column_end'],
        annotation_text_id: annotation_text.id,
        submission_file_id: submission.submission_files.find_by(filename: data['filename']).id,
        creator_id: self.role.id,
        creator_type: self.role.type,
        is_remark: !result.remark_request_submitted_at.nil?,
        annotation_number: count + i,
        result_id: result.id
      )
    end
  end

  def unzip_file_data(file_data)
    return Zlib.gunzip(file_data['content']) if file_data['compression'] == 'gzip'
    file_data['content']
  end
end
