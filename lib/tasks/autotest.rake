namespace :db do
  desc 'Create autotest for assignment 5'
  task :autotest => :environment do
    puts 'Add autotest scripts'

    test_file_location = File.join('db', 'data', 'autotest_files')
    test_file_destination = MarkusConfigurator.autotest_client_dir
    original_test_files = Dir.glob(File.join(test_file_location, '*'))

    # remove previously existing autotest files to create room for new ones
    FileUtils.rm_rf Dir.glob(File.join(test_file_destination, '*'))

    # create A5 directory to put new autotest files into
    test_file_destination = File.join(test_file_destination, 'A5')
    FileUtils.makedirs test_file_destination

    # copy test files into the destination directory
    FileUtils.cp original_test_files, test_file_destination

    assignment = Assignment.find_by(short_identifier: 'A5')

    # get the criteria from assignment 5
    criteria = assignment.get_criteria

    # get the test files stored in db/data/autotest_files
    test_files = Dir.glob(File.join(test_file_destination, '*')).select {|f| File.file?(f)}

    test_files.zip(criteria) do |test_file, criterion|
      TestScript.create(
        assignment: assignment,
        seq_num: 0,
        file_name: File.basename(test_file),
        description: "",
        run_by_instructors: true,
        run_by_students: true,
        halts_testing: true,
        display_description: "do_not_display",
        display_run_status: "do_not_display",
        display_marks_earned: "do_not_display",
        display_input: "do_not_display",
        display_expected_output: "do_not_display",
        display_actual_output: "display_after_submission",
        timeout: 30,
        criterion: criterion
      )
    end

    # collect the submissions from all groupings for assignment 5 so they can be autotested
    assignment.groupings.find_each do |grouping|
      # create new submission for each grouping
      time = assignment.submission_rule.calculate_collection_time.localtime
      Submission.create_by_timestamp(grouping, time)
      # collect submission
      grouping.is_collected = true
      grouping.save
    end
  end
end
