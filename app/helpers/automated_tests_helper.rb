# Helper methods for Testing Framework forms
module AutomatedTestsHelper

  # Prototype code that needs to be removed:
  # Methods: add_test_file_link, add_lib_file_link, add_parser_file_link
  # $F, .insert() and .replace() are all Prototype functions
  # Places with $('id') need to be replaced with something like jQuery('#id')

  def add_test_file_link(name, form)
    link_to_function name do |page|
      test_file = render(partial: 'test_file',
                         locals: {form: form,
                                     test_file: TestFile.new,
                                     file_type: 'test'})
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_file_id = new Date().getTime();
          $('test_files').insert({bottom: "#{ escape_javascript test_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_file_id) });
          $('assignment_test_files_' + new_test_file_id + '_filename').focus();
        } else {
          alert("#{I18n.t('automated_tests.add_test_file_alert')}");
        }
      }
    end
  end

  def add_lib_file_link(name, form)
    link_to_function name do |page|
      test_file = render(partial: 'test_file',
                         locals: {form: form,
                                     test_file: TestFile.new,
                                     file_type: 'lib'})
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_file_id = new Date().getTime();
          $('lib_files').insert({bottom: "#{ escape_javascript test_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_file_id) });
          $('assignment_test_files_' + new_test_file_id + '_filename').focus();
        } else {
          alert("#{I18n.t('automated_tests.add_lib_file_alert')}");
        }
      }
    end
  end

  def add_parser_file_link(name, form)
    link_to_function name do |page|
      test_file = render(partial: 'test_file',
                         locals: {form: form,
                                     test_file: TestFile.new,
                                     file_type: 'parse'})
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_file_id = new Date().getTime();
          $('parser_files').insert({bottom: "#{ escape_javascript test_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_file_id) });
          $('assignment_test_files_' + new_test_file_id + '_filename').focus();
        } else {
          alert("#{I18n.t('automated_tests.add_parser_file_alert')}");
        }
      }
    end
  end

  def create_ant_test_files(assignment)
    # Create required ant test files - build.xml and build.properties
    if assignment && assignment.test_files.empty?
      @ant_build_file = TestFile.new
      @ant_build_file.assignment = assignment
      @ant_build_file.filetype = 'build.xml'
      @ant_build_file.filename = 'tempbuild.xml'        # temporary placeholder for now
      @ant_build_file.save(validate: false)

      @ant_build_prop = TestFile.new
      @ant_build_prop.assignment = assignment
      @ant_build_prop.filetype = 'build.properties'
      @ant_build_prop.filename = 'tempbuild.properties' # temporary placeholder for now
      @ant_build_prop.save(validate: false)

      # Setup Testing Framework repository
      test_dir = File.join(
                  MarkusConfigurator.markus_config_automated_tests_repository,
                  assignment.short_identifier)
      FileUtils.makedirs(test_dir)

      assignment.reload
    end
  end

  # Process Testing Framework form
  # - Process new and updated test files (additional validation to be done at the model level)
  def process_test_form(assignment, params)

    # Hash for storing new and updated test files
    updated_files = {}

    # Retrieve all test file entries
    testfiles = params[:test_files_attributes]

    # First check for duplicate filenames:
    filename_array = []
    testfiles.values.each do |tfile|
      if tfile['filename'].respond_to?(:original_filename)
        fname = tfile['filename'].original_filename
        # If this is a duplicate filename, raise error and return
        if filename_array.include?(fname)
          raise I18n.t('automated_tests.duplicate_filename') + fname
        else
          filename_array << fname
        end
      end
    end

    # Filter out files that need to be created and updated:
    testfiles.each_key do |key|

      tfile = testfiles[key]

      # Can't mass assign assignment_id
      tfile.delete(:assignment_id)

      # Check to see if this is an update or a new file:
      # - If 'id' exists, this is an update
      # - If 'id' does not exist, this is a new test file
      tf_id = tfile['id']

      # If only the 'id' exists in the hash, other attributes were not updated so we skip this entry.
      # Otherwise, this test file possibly requires an update
      if tf_id != nil && tfile.size > 1

        # Find existing test file to update
        @existing_testfile = TestFile.find_by_id(tf_id)
        if @existing_testfile
          # Store test file for any possible updating
          updated_files[key] = tfile
        end
      end

      # Test file needs to be created since record doesn't exist yet
      if tf_id.nil? && tfile['filename']
        updated_files[key] = tfile
      end
    end

    # Update test file attributes
    assignment.test_files_attributes = updated_files

    # Update assignment enable_test and tokens_per_day attributes
    assignment.enable_test = params[:enable_test]
    num_tokens = params[:tokens_per_day]
    if num_tokens
      assignment.tokens_per_day = num_tokens
    end

    assignment
  end

  # Verify tests can be executed
  def can_run_test?
    if @current_user.admin?
      true
    elsif @current_user.ta?
      true
    elsif @current_user.student?
      # Make sure student belongs to this group
      unless @current_user.accepted_groupings.include?(@grouping)
        return false
      end
      t = @grouping.token
      if t == nil
        raise I18n.t('automated_tests.missing_tokens')
      end
      if t.tokens > 0
        t.decrease_tokens
        true
      else
        false
      end
    end
  end

  # Export group repository for testing
  def export_repository(group, repo_dest_dir)
    # Create the test framework repository
    unless File.exists?(MarkusConfigurator.markus_config_automated_tests_repository)
      FileUtils.mkdir(MarkusConfigurator.markus_config_automated_tests_repository)
    end

    # Delete student's assignment repository if it already exists
    repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, group.repo_name)
    if File.exists?(repo_dir)
      FileUtils.rm_rf(repo_dir)
    end

    return group.repo.export(repo_dest_dir)
    rescue Exception => e
      return "#{e.message}"
  end

  # Export configuration files for testing
  def export_configuration_files(assignment, group, repo_dest_dir)
    assignment_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)
    repo_assignment_dir = File.join(repo_dest_dir, assignment.short_identifier)

    # Store the Api key of the grader or the admin in the api.txt file in the exported repository
    FileUtils.touch(File.join(assignment_dir, 'api.txt'))
    api_key_file = File.open(File.join(repo_assignment_dir, 'api.txt'), 'w')
    api_key_file.write(current_user.api_key)
    api_key_file.close

    # Create a file "export.properties" where group_name and assignment name are stored for Ant
    FileUtils.touch(File.join(assignment_dir, 'export.properties'))
    api_key_file = File.open(File.join(repo_assignment_dir, 'export.properties'), 'w')
    api_key_file.write('group_name = ' + group.group_name + "\n")
    api_key_file.write('assignment = ' + assignment.short_identifier + "\n")
    api_key_file.close
  end

  # Delete test repository directory
  def delete_test_repo(group, repo_dest_dir)
    repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, group.repo_name)
    # Delete student's assignment repository if it exists
    if File.exists?(repo_dir)
      FileUtils.rm_rf(repo_dir)
    end
  end

  # Copy files needed for testing
  def copy_ant_files(assignment, repo_dest_dir)
    # Check if the repository where you want to copy Ant files to exists
    unless File.exists?(repo_dest_dir)
      raise I18n.t('automated_tests.dir_not_exist', {dir: repo_dest_dir})
    end

    # Create the src repository to put student's files
    assignment_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)
    repo_assignment_dir = File.join(repo_dest_dir, assignment.short_identifier)
    FileUtils.mkdir(File.join(repo_assignment_dir, 'src'))

    # Move student's source files to the src repository
    pwd = FileUtils.pwd
    FileUtils.cd(repo_assignment_dir)
    FileUtils.mv(Dir.glob('*'), File.join(repo_assignment_dir, 'src'), force: true )

    # You always have to come back to your former working directory if you want to avoid errors
    FileUtils.cd(pwd)

    # Copy the build.xml, build.properties Ant Files and api_helpers (only one is needed)
    if File.exists?(assignment_dir)
      FileUtils.cp(File.join(assignment_dir, 'build.xml'), repo_assignment_dir)
      FileUtils.cp(File.join(assignment_dir, 'build.properties'), repo_assignment_dir)
      FileUtils.cp('lib/tools/api_helper.rb', repo_assignment_dir)
      FileUtils.cp('lib/tools/api_helper.py', repo_assignment_dir)

      # Copy the test folder:
      # If the current user is a student, do not copy tests that are marked 'is_private' over
      # Otherwise, copy all tests over
      if @current_user.student?
        # Create the test folder
        assignment_test_dir = File.join(assignment_dir, 'test')
        repo_assignment_test_dir = File.join(repo_assignment_dir, 'test')
        FileUtils.mkdir(repo_assignment_test_dir)
        # Copy all non-private tests over
        assignment.test_files
                  .where(filetype: 'test', is_private: 'false')
                  .each do |file|
          FileUtils.cp(File.join(assignment_test_dir, file.filename), repo_assignment_test_dir)
        end
      else
        if File.exists?(File.join(assignment_dir, 'test'))
          FileUtils.cp_r(File.join(assignment_dir, 'test'), File.join(repo_assignment_dir, 'test'))
        end
      end

      # Copy the lib folder
      if File.exists?(File.join(assignment_dir, 'lib'))
        FileUtils.cp_r(File.join(assignment_dir, 'lib'), repo_assignment_dir)
      end

      # Copy the parse folder
      if File.exists?(File.join(assignment_dir, 'parse'))
        FileUtils.cp_r(File.join(assignment_dir, 'parse'), repo_assignment_dir)
      end
    else
      raise I18n.t('automated_tests.dir_not_exist', {dir: assignment_dir})
    end
  end

  # Execute Ant which will run the tests against the students' code
  def run_ant_file(result, assignment, repo_dest_dir)
    # Check if the repository where you want to copy Ant files to exists
    unless File.exists?(repo_dest_dir)
      raise I18n.t('automated_tests.dir_not_exist', {dir: repo_dest_dir})
    end

    # Go to the directory where the Ant program must be run
    repo_assignment_dir = File.join(repo_dest_dir, assignment.short_identifier)
    pwd = FileUtils.pwd
    FileUtils.cd(repo_assignment_dir)

    # Execute Ant and log output in a temp logfile
    logfile = 'build_log.xml'
    system ("ant -logger org.apache.tools.ant.DefaultLogger -logfile #{logfile}")

    # Change back to the Rails Working directory
    FileUtils.cd(pwd)

    # File to store build details
    filename = I18n.l(Time.zone.now, format: :ant_date) + '.log'
    # Status of Ant build
    status = ''

    # Handle output depending on if the system command:
    # - executed successfully (ie. Ant returns a BUILD SUCCESSFUL exit(0))
    # - failed (ie. Ant returns a BUILD FAILED exit(1) possibly due to a compilation issue) or
    # - errored out for an unknown reason (ie. Ant returns exit != 0 or 1)
    if $?.exitstatus == 0
      # Build ran succesfully
      status = 'success'
    elsif $?.exitstatus == 1
      # Build failed
      status = 'failed'

      # Go back to the directory where the Ant program must be run
      pwd = FileUtils.pwd
      FileUtils.cd(repo_assignment_dir)

      # Re-run in verbose mode and log issues for diagnosing purposes
      system ("ant -logger org.apache.tools.ant.XmlLogger -logfile #{logfile} -verbose")

      # Change back to the Rails Working directory
      FileUtils.cd(pwd)
    else
      # Otherwise, some other unknown error with Ant has occurred so we simply log
      # the output for problem diagnosing purposes.
      status = 'error'
    end

    # Read in test output logged in build_log.xml
    file = File.open(File.join(repo_assignment_dir, logfile), 'r')
    data = String.new
    file.each_line do |line|
      data += line
    end
    file.close

    # If the build was successful, send output to parser(s)
    if $?.exitstatus == 0
      data = parse_test_output(repo_assignment_dir, assignment, logfile, data)
    end

    # Create TestResult object
    # (Build failures and errors will be logged and stored as well for diagnostic purposes)
    TestResult.create(filename: filename,
      file_content: data,
      submission_id: result.submission.id,
      status: status,
      user_id: @current_user.id)
  end

  # Send output to parser(s) if any
  def parse_test_output(repo_assignment_dir, assignment, logfile, data)
    # Store test output
    output = data

    # If any test parsers exist, execute Ant's 'parse' target
    if assignment.test_files.find_by_filetype('parse')
      # Go to the directory where the Ant program must be run
      pwd = FileUtils.pwd
      FileUtils.cd(repo_assignment_dir)

      # Run Ant to parse test output
      system ("ant parse -logger org.apache.tools.ant.DefaultLogger -logfile #{logfile} -Doutput=#{data}")

      # Change back to the Rails Working directory
      FileUtils.cd(pwd)

      # Read in test output logged in logfile
      file = File.open(File.join(repo_assignment_dir, logfile), 'r')
      output = String.new
      file.each_line do |line|
        output += line
      end
      file.close
    end

    # Return parsed (or unparsed) test output
    output
  end
end
