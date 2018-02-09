namespace :db do
  desc 'Create autotest for assignment 5'
  task :autotest => :environment do
    puts 'Autotest: 1'

    test_file_location = File.join('db', 'data', 'autotest_files')
    test_file_destination = File.join('data', 'dev', 'autotest')
    original_test_files = Dir.glob(File.join(test_file_location, '*'))

    # remove previously existing autotest files to create room for new ones
    FileUtils.rm_rf Dir.glob(File.join(test_file_destination, '*'))

    # create A5 directory to put new autotest files into
    test_file_destination = File.join(test_file_destination, 'A5')
    FileUtils.makedirs test_file_destination

    # copy test files into the destination directory
    FileUtils.cp original_test_files, test_file_destination

    assignment = Assignment.find_by(short_identifier: 'A5')
    unless assignment.nil?
      test_files = Dir.glob(File.join(test_file_destination, '*')).select {|f| File.file?(f)}
      test_files.each do |test_file|
        TestScript.create(
          assignment_id: assignment.id,
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
          timeout: 30
        )
      end
    end
  end
end


