class TestRun < ApplicationRecord
  enum :status, { in_progress: 0, complete: 1, cancelled: 2, failed: 3 }
  has_many :test_group_results, dependent: :destroy
  has_many :feedback_files, through: :test_group_results
  belongs_to :test_batch, optional: true
  belongs_to :submission, optional: true
  belongs_to :grouping
  belongs_to :role

  has_one :course, through: :role

  validate :courses_should_match
  validate :autotest_test_id_uniqueness
  before_save :unset_autotest_test_id

  SETTINGS_FILES_DIR = (Settings.file_storage.autotest || File.join(Settings.file_storage.default_root_path,
                                                                    'autotest')).freeze
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
      new_overall_comments = []
      results['test_groups'].each do |result|
        test_group_result = create_test_group_result(result)
        marks_total, marks_earned = 0, 0
        result['tests'].each_with_index do |test, i|
          ApplicationRecord.transaction do
            test_group_result.test_results.create!(
              name: test['name'],
              status: test['status'],
              marks_earned: test['marks_earned'],
              output: test['output'].gsub("\x00", '\\u0000'),
              marks_total: test['marks_total'],
              time: test['time'],
              position: i + 1
            )
            marks_earned += test['marks_earned']
            marks_total += test['marks_total']
          rescue StandardError => e
            extra_info = test_group_result.extra_info
            test_name = test['name'].nil? ? '' : "#{test['name']} - "
            if extra_info.nil?
              test_group_result.update(extra_info: test_name + e.message)
            else
              test_group_result.update(extra_info: extra_info + "\n" + test_name + e.message)
            end
          end
        end
        create_annotations(result['annotations'])
        result['feedback']&.each { |feedback| create_feedback_file(feedback, test_group_result) }

        if result['tags'].present?
          add_tags(result['tags'])
        end
        if result['overall_comment'].present?
          new_overall_comments.append(result['overall_comment'])
        end
        if result['extra_marks'].present?
          add_extra_marks(result['extra_marks'])
        end
        test_group_result.update(marks_earned: marks_earned,
                                 marks_total: marks_total)
      end
      self.submission&.set_autotest_marks
      add_overall_comment(new_overall_comments)
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

  def create_test_group_result(result)
    test_group_id = result.dig('extra_info', 'test_group_id')
    test_group = TestGroup.find_by(id: test_group_id)
    test_group.test_group_results.create(
      test_run_id: self.id,
      extra_info: extra_info_string(result),
      time: result['time'] || 0,
      error_type: error_type(result)
    )
  end

  def add_extra_marks(extra_marks)
    return if self.submission.nil?
    submission_result = self.grouping&.current_submission_used&.get_latest_result

    extra_marks.each do |extra_mark|
      unit = extra_mark['unit']
      mark = extra_mark['mark']

      ExtraMark.create(
        unit: unit,
        extra_mark: mark,
        result_id: submission_result.id,
        description: extra_mark['description']
      )
    end
  end

  def add_tags(tag_data)
    tag_data.each do |new_tag|
      tag_to_add = Tag.find_or_create_by(name: new_tag['name'], assessment_id: self.grouping.assessment_id) do |tag|
        tag.description = tag['description']
        tag.role_id = self.role_id
      end

      if self.grouping.tags.exclude?(tag_to_add)
        self.grouping.tags << tag_to_add
      end
    end
  end

  def add_overall_comment(new_overall_comments)
    return if self.submission.nil? || new_overall_comments.blank?

    # Convert to block quotes
    new_overall_comments.each do |comment|
      comment.prepend('> ')
      comment.gsub!("\n", "\n> ")
    end
    joined_overall_comments = new_overall_comments.join("\n\n")

    # Add header
    joined_overall_comments.prepend(
      I18n.t(
        'results.annotation.feedback_generated_header',
        time: I18n.l(self.updated_at)
      ) + "\n"
    )

    if self.submission.current_result.overall_comment.blank?
      self.submission.current_result.update(overall_comment: joined_overall_comments)
    else
      self.submission.current_result.update(
        overall_comment: self.submission.current_result.overall_comment + "\n\n" + joined_overall_comments
      )
    end
  end

  def create_feedback_file(feedback_data, test_group_result)
    return if feedback_data.nil? || test_group_result.nil?

    unzipped_feedback_data = unzip_file_data(feedback_data)
    test_group_result.feedback_files.create(
      filename: unzipped_feedback_data['filename'],
      mime_type: unzipped_feedback_data['mime_type'],
      file_content: unzipped_feedback_data['content'],
      submission: test_group_result.test_run&.submission
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
      Annotation.create(
        line_start: data['line_start'],
        line_end: data['line_end'],
        column_start: data['column_start'],
        column_end: data['column_end'],
        x1: data['x1'],
        x2: data['x2'],
        y1: data['y1'],
        y2: data['y2'],
        start_node: data['start_node'],
        start_offset: data['start_offset'],
        end_node: data['end_node'],
        end_offset: data['end_offset'],
        annotation_text_id: annotation_text.id,
        submission_file_id: submission.submission_files.find_by(filename: data['filename']).id,
        creator_id: self.role.id,
        creator_type: self.role.type,
        is_remark: !result.remark_request_submitted_at.nil?,
        annotation_number: count + i,
        type: data['type'] || 'TextAnnotation',
        result_id: result.id
      )
    end
  end

  def unzip_file_data(file_data)
    file_data['content'] = Zlib.gunzip(file_data['content']) if file_data['compression'] == 'gzip'
    if file_data['content'].size > self.course.max_file_size
      size_diff = file_data['content'].size - self.course.max_file_size
      file_data['mime_type'] = 'text'
      file_data['content'] = I18n.t('oversize_feedback_file',
                                    file_size: ActiveSupport::NumberHelper.number_to_human_size(size_diff),
                                    max_file_size: self.course.max_file_size / 1_000_000)
    end
    file_data
  end

  def unset_autotest_test_id
    return if self.in_progress?
    self.autotest_test_id = nil
  end

  def autotest_test_id_uniqueness
    return unless self.autotest_test_id

    other_test_runs = TestRun.joins(role: :course)
                             .where('courses.autotest_setting_id': self.course.autotest_setting_id,
                                    autotest_test_id: self.autotest_test_id)
                             .where.not(id: self.id)
                             .exists?
    errors.add(:base, 'autotest_test_id must be unique scoped to autotest settings') if other_test_runs
  end
end
