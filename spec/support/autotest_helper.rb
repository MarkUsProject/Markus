module AutotestHelper

  def setup_autotest_environment(test_name, n_test_scripts: 1)
    # Set up environment for performing autotests:
    # - {test_name}.py is a student script used to simulate a
    #   test outcome from the autester. A file named {test_name}.py
    #   should exist in spec/fixtures/files/submission_files/autotest/
    #
    # - Test scripts will simply write the output of these student
    #   submissions to stdout/stderr

    create(:test_server) if TestServer.first.nil?

    filename = 'submission.py'

    # create assignment
    assignment = create(:assignment_for_autotesting)
    create(:assignment_file, assignment: assignment, filename: filename)

    # copy test script files into the destination directory
    test_file_destination = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.repository_folder)
    FileUtils.makedirs test_file_destination
    n = '00'
    n_test_scripts.times do
      test_file_name = "autotest_#{n.next!}.sh"
      test_file_path = File.join(test_file_destination, test_file_name)
      File.open(test_file_path, 'w') do |f|
        f.write("#!/bin/bash\n\npython submission.py $0")
      end
      create(:test_script, assignment: assignment, file_name: test_file_name)
    end

    # create student, grouping etc.
    group = create(:group)
    student = create(:student)
    grouping = create(:grouping_with_inviter, assignment: assignment, group: group, inviter: student)
    submission = create(:version_used_submission, grouping: grouping)
    result = create(:incomplete_result, submission: submission)

    # add submission file to repo
    file_path = File.join('files', 'submission_files', 'autotest', "#{test_name}.py")
    begin
      file = fixture_file_upload(file_path)
    rescue RuntimeError
      file = nil
    end

    repo_dir = File.join(AutomatedTestsClientHelper::STUDENTS_DIR,
                         grouping.group.repo_name,
                         assignment.repository_folder)
    FileUtils.makedirs(repo_dir)
    autotest_submission_file = File.join(repo_dir, filename)
    unless file.nil?
      File.open(autotest_submission_file, 'w') { |f| f.write(file.read) }
    end

    # collect submission
    grouping.is_collected = true
    grouping.save

    [assignment, submission, result, grouping]
  end

  def run_autotests(test_names, current_user, test_server_user, global_timeout: 10)
    raise 'minimum global timeout is 2 seconds' unless global_timeout > 2
    expected = {}
    finished = []
    test_names.each do |test_name|
      args = get_test_args(test_name, current_user, test_server_user)
      grouping_id = args[4]
      AutotestRunJob.perform_now(*args)
      expected[test_name] = grouping_id
    end
    interval = [ (global_timeout / 10.0).floor, 2 ].max
    begin
      wait global_timeout, interval do
        finished = TestScriptResult.where(grouping_id: expected.values).select(:grouping_id).distinct
        if finished.size < expected.size
          raise RuntimeError
        end
      end
    rescue RuntimeError => e
      n_remaining = expected.size - finished.size
      raise e, "global timeout reached (#{global_timeout} seconds), #{n_remaining} test not completed", e.backtrace
    end
    expected
  end

  def get_server_opts
    server = Rails::Server.new
    server.default_options
  end

  def get_test_args(test_name, current_user, test_server_user)
    n_test_scripts = test_name.match(/_2s_/).nil? ? 1 : 2
    assignment, submission, _, grouping = setup_autotest_environment(test_name, n_test_scripts: n_test_scripts)

    test_scripts = assignment.instructor_test_scripts.order(:seq_num).pluck_to_hash(:file_name, :timeout)

    opts = get_server_opts
    host_with_port = "http://#{opts[:Host]}:#{opts[:Port]}"
    [host_with_port, test_scripts, current_user.api_key, test_server_user.api_key, grouping.id, submission.id]
  end

  def create_with_api_key(type)
    user = create(type.to_s)
    if user.api_key.nil?
      user.set_api_key
      user.save
    end
    user
  end

  def get_test_names
    submission_file_loc = Rails.root.join 'spec', 'fixtures', 'files', 'submission_files', 'autotest'
    student_files = Dir.glob File.join(submission_file_loc, '*')
    student_files.map { |sf| File.basename sf, '.py' }
  end
end
