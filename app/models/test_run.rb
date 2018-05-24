class TestRun < ApplicationRecord
  has_many :test_script_results, dependent: :destroy
  belongs_to :test_batch
  belongs_to :submission
  belongs_to :grouping, required: true
  belongs_to :user, required: true

  validates_presence_of :revision_identifier
  validates_numericality_of :queue_len, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true
  validates_numericality_of :avg_pop_interval, greater_than_or_equal_to: 0, only_integer: true, allow_nil: true

  def create_test_script_result(test_script_name, time = 0)
    test_script = TestScript.find_by(assignment: submission.assignment, file_name: test_script_name)
    test_script_results.create(
      test_script: test_script,
      marks_earned: 0.0,
      marks_total: 0.0,
      time: time)
    # TODO: Handle extra_info
  end

  def create_error_for_all_test_scripts(test_scripts, errors)
    test_scripts.each do |test_script|
      test_script_result = create_test_script_result(test_script)
      errors.each do |error|
        test_script_result.create_test_error_result(error[:name], error[:message])
      end
    end
    submission&.set_marks_for_tests
  end

  def create_test_script_result_from_json(json_test_script)

    # create test result
    file_name = json_test_script['file_name']
    time = json_test_script['time'].nil? ? 0 : json_test_script['time']
    new_test_script_result = create_test_script_result(file_name, time)
    json_tests = json_test_script['test']
    if json_tests.nil?
      new_test_script_result.create_test_error_result(I18n.t('automated_tests.test_result.all_tests_stdout'),
                                                      I18n.t('automated_tests.test_result.no_tests'))
      return new_test_script_result
    end

    # process tests
    all_marks_earned = 0.0
    all_marks_total = 0.0
    json_tests.each do |json_test|
      begin
        marks_earned, marks_total = new_test_script_result.create_test_result_from_json(json_test)
      rescue
        # with malformed xml, test results could be valid only up to a certain test
        # similarly, the test script can signal a serious failure that requires stopping and assigning zero marks
        all_marks_earned = 0.0
        break
      end
      all_marks_earned += marks_earned
      all_marks_total += marks_total
    end
    new_test_script_result.marks_earned = all_marks_earned
    new_test_script_result.marks_total = all_marks_total
    new_test_script_result.save

    new_test_script_result
  end

  def create_test_script_results_from_json(test_output)

    test_scripts = [] # TODO: get all TestScripts in create_error_for_all_test_scripts
    stderr = '' # TODO: print them separately per script, not as TestResults
    # check that results are well-formed and don't crash the parser
    json_root = nil
    begin
      json_root = JSON.parse(test_output)
    rescue => e
      errors = [{ name: I18n.t('automated_tests.test_result.all_tests'),
                  message: I18n.t('automated_tests.test_result.bad_results', { json: e.message }) }]
      unless stderr.blank?
        errors << { name: I18n.t('automated_tests.test_result.all_tests'),
                    message: I18n.t('automated_tests.test_result.err_results', { errors: stderr }) }
      end
      create_error_for_all_test_scripts(test_scripts, errors)
      return
    end
    json_test_run = json_root['testrun']
    json_test_scripts = json_test_run.nil? ? nil : json_test_run['test_script']
    if json_test_run.nil? || json_test_scripts.nil?
      errors = [{ name: I18n.t('automated_tests.test_result.all_tests'),
                  message: I18n.t('automated_tests.test_result.bad_results', { json: test_output }) }]
      unless stderr.blank?
        errors << { name: I18n.t('automated_tests.test_result.all_tests'),
                    message: I18n.t('automated_tests.test_result.err_results', { errors: stderr }) }
      end
      create_error_for_all_test_scripts(test_scripts, errors)
      return
    end

    # process results
    new_test_script_results = {}
    json_test_scripts.each do |json_test_script|
      file_name = json_test_script['file_name']
      if file_name.nil? # with malformed json, some test script results could be valid and some won't, recover later
        next
      end
      new_test_script_result = create_test_script_result_from_json(json_test_script)
      new_test_script_results[file_name] = new_test_script_result
    end

    test_scripts.each do |file_name|
      # try to recover from malformed xml at the test script level
      new_test_script_result = new_test_script_results[file_name]
      if new_test_script_result.nil?
        new_test_script_result = create_test_script_result(file_name)
        new_test_script_result.create_test_error_result(I18n.t('automated_tests.test_result.all_tests'),
                                                        I18n.t('automated_tests.test_result.bad_results',
                                                               { json: test_output }))
        new_test_script_results[file_name] = new_test_script_result
      end
      # add unhandled errors to all test scripts
      unless stderr.blank?
        new_test_script_result.create_test_error_result(I18n.t('automated_tests.test_result.all_tests'),
                                                        I18n.t('automated_tests.test_result.err_results',
                                                               { errors: stderr }))
      end
    end

    # set the marks assigned by the test
    submission&.set_marks_for_tests
  end
end
