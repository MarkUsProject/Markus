require 'libxml'
require 'open3'

# Helper methods for Testing Framework forms
module AutomatedTestsHelper
  include LibXML

  # Find the list of test scripts to run the test. Return the list of
  # test scripts in the order specified by seq_num (running order)
  def scripts_to_run(assignment, call_on)
    # Find all the test scripts of the current assignment
    all_scripts = TestScripts.find_by_assignment(assignment)

    list_run_scripts = Array.new

    # If the test run is requested at collection (by Admin or TA),
    # All of the test scripts should be run.
    if call_on == "collection"
      list_run_scripts = all_scripts
    else
      # If the test run is requested at submission or upon request,
      # verify the script is allowed to run.
      for script in all_scripts
        if (call_on == "submission") && script.run_on_submission
          list_run_scripts.insert(list_run_scripts.length, script)
        elsif (call_on == "request") && script.run_on_request
          list_run_scripts.insert(list_run_scripts.length, script)
        end
      end
    end

    # TODO: verify this
    # list_run_scripts should be sorted because TestScript has index
    # ["assignment_id", "seq_num"]. Perform a check here.
    ctr = 0
    while ctr < list_run_scripts.length - 1
      if (list_run_scripts[ctr].seq_num) > (list_run_scripts[ctr+1].seq_num)
        raise "list_run_scripts is not sorted"
      end
      ctr = ctr + 1
    end

    return list_run_scripts
  end

  # Given a list of test scripts, verify if a token is required in
  # order to run these scripts. If at least one test script requires
  # a token, return true. If none of the test scripts require a token,
  # return false.
  def require_token?(list_of_scripts)
=begin
      t = @grouping.token
      if t == nil
        raise I18n.t("automated_tests.missing_tokens")
      end
      # TODO: check this only when the scripts require token
      if t.tokens > 0
        t.decrease_tokens
        return true
      else
        return false
      end
=end
    for script in list_of_scripts
      if script.uses_token
        return true
      end
    end

    return false
  end

  # Delete test repository directory
  def delete_test_repo(group, repo_dir)
    # Delete student's assignment repository if it already exists
    if (File.exists?(repo_dir))
      FileUtils.rm_rf(repo_dir)
    end
  end

  # Export group repository for testing. Students' submitted files
  # are stored in the group svn repository. They must be exported
  # before copying to the test server.
  def export_group_repo(group, repo_dir)
    # Create the test framework repository
    if !(File.exists?(MarkusConfigurator.markus_config_automated_tests_repository))
      FileUtils.mkdir(MarkusConfigurator.markus_config_automated_tests_repository)
    end

    # Delete student's assignment repository if it already exists
    delete_test_repo(group, repo_dir)

    # export
    return group.repo.export(repo_dir)
    rescue Exception => e
      return "#{e.message}"
  end

  # Verify the user has the permission to run the tests - admin
  # and graders always have the permission, while student has to
  # belong to the group.
  def has_permission?()
    if @current_user.admin?
      return true
    elsif @current_user.ta?
      return true
    elsif @current_user.student?
      # Make sure student belongs to this group
      if not @current_user.accepted_groupings.include?(@grouping)
        return false
      else
        return true
      end
    end
  end

  # Verify that MarkUs has some files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one test script and
  # source files are successfully exported.
  def files_available?()
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @assignment.short_identifier)
    src_dir = @repo_dir

    if !(File.exists?(test_dir))
      return false
    elsif !(File.exists?(src_dir))
      return false
    end

    scripts = TestScript.find_all_by_assignment(@assignment)
    if scripts.empty?
      return false
    end

    return true
  end

  # From a list of test servers, choose the next available server
  # using round-robin. Return -1 if no server is available
  # TODO: keep track of the max num of tests running on a server
  def choose_test_server()

    @list_of_servers = MarkusConfigurator.markus_ate_test_server_hosts.split(' ')

    if @last_server.define?
      # find the index of the last server, and return the next index
      @last_server = (@list_of_servers.index(@last_server) + 1) % MarkusConfigurator.markus_ate_num_test_servers
    else
      @last_server = 0
    end

    return @last_server

  end

  # Launch the test on the test server by scp files to the server
  # and run the script.
  # This function returns two values: first one is the output from
  # stdout or stderr, depending on whether the execution passed or
  # had error; the second one is a boolean variable, true => execution
  # passeed, false => error occurred.
  def launch_test(server_id, assignment, repo_dir, call_on)
    # Get src_dir
    src_dir = repo_dir

    # Get test_dir
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)

    # Get the name of the test server
    server = @list_of_servers[server_id]

    # Get the directory and name of the test runner script
    script = MarkusConfigurator.markus_ate_test_runner_script_name

    # Get the test run directory of the files
    run_dir = MarkusConfigurator.markus_ate_test_run_directory

    # Delete the test run directory to remove files from previous test
    stdout, stderr, status = Open3.capture3("ssh #{server} rm -rf #{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end

    # Recreate the test run directory
    stdout, stderr, status = Open3.capture3("ssh #{server} mkdir #{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end

    # Securely copy source files, test files and test runner script to run_dir
    stdout, stderr, status = Open3.capture3("scp -p -r #{src_dir}/* #{server}:#{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end
    stdout, stderr, status = Open3.capture3("scp -p -r #{test_dir}/* #{server}:#{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end
    stdout, stderr, status = Open3.capture3("ssh #{server} cp #{script} #{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end

    # Find the test scripts for this test run, and parse the argument list
    list_run_scripts = scripts_to_run(assignment, call_on)
    arg_list = ""
    for script in list_run_scripts
      arg_list = arg_list + " --name #{script.script_name} --marks #{script.max_marks} --halts #{script.halts_testing}"
    end

    # Run script
    script_name = script[(script.rindex('/') + 1) .. (script.length - 1)]
    stdout, stderr, status = Open3.capture3("ssh #{server} \"cd #{run_dir}; ./#{script_name}#{arg_list}\"")
    if !(status.success?)
      return [stderr, false]
    else
      return [stdout, true]
    end

  end

  def process_result(result)
    parser = XML::Parser.string(result)

    # parse the xml doc
    doc = parser.parse

    # find all the tests nodes and loop over them
    tests = doc.find("/test_suite/test")
    tests.each do |test|
      test_record = TestResult.new

      # loop through the childs of all the tests nodes
      test.each_child do |child|
        # save the node's data according to it's name
        if child.name == "submission_id" then
          test_record.submission_id = child.content

        elsif child.name == "test_script_id" then
          test_record.test_script_id = child.content

        elsif child.name == "input" then
          test_record.input_description = child.content

        elsif child.name == "status" then
          test_record.completion_status = child.content

        elsif child.name == "marks" then
          test_record.marks_earned = child.content

        elsif child.name == "output" then
          test_record.actual_output = child.content

        elsif child.name == "expected" then
          test_record.expected_output = child.content

        elsif child.name == "test_script_id" then
          test_record.actual_output = child.content

        else
          # if the tag was not recognized, raise an error
          if child.name != "text" then
            raise "Error: malformed xml from test runner. Unclaimed tag: " +
              child.name
          end

        end
      end
      # save the record
      test_record.save
    end
  end

  # Create a repository for the test scripts, and a placeholder script
  def create_test_scripts(assignment)
    script_placeholder = TestScript.new
    script_placeholder.assignment = assignment
    # more..
    script_paceholder.save(:validate => false)

    # Setup Testing Framework repository
    test_dir = File.join(
                MarkusConfigurator.markus_config_automated_tests_repository,
                assignment.short_identifier)
    FileUtils.makedirs(test_dir)

    assignment.reload
  end

 def add_test_script_link(name, form)
    link_to_function name do |page|
      new_test_script = TestScript.new
      test_script = render(:partial => 'test_script_upload',
                         :locals => {:form => form,
                                     :test_script => new_test_script})

      test_script_options = render(:partial => 'test_script_options',
                         :locals => {:form => form,
                                     :test_script => new_test_script })
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_script_id = new Date().getTime();
          $('test_script_files').insert({bottom: "#{ escape_javascript test_script }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_script_id) });
          $('test_script_options').insert({bottom: "#{ escape_javascript test_script_options }" });
        } else {
          alert("#{I18n.t("automated_tests.add_test_script_file_alert")}");
        }
      }
    end
  end

  def add_test_support_file_link(name, form)
    link_to_function name do |page|
      test_support_file = render(:partial => 'test_support_file_upload',
                         :locals => {:form => form,
                                     :test_support_file => TestSupportFile.new })
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_support_file_id = new Date().getTime();
          $('test_support_files').insert({bottom: "#{ escape_javascript test_support_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_support_file_id) });
        } else {
          alert("#{I18n.t("automated_tests.add_test_support_file_alert")}");
        }
      }
    end
  end

  #need to implement this
  #this is called when a new test script file is added
  def add_test_script_options(form)

    #TODO

  end

  # NEEDS TO BE UPDATES
  # Process Testing Framework form
  # - Process new and updated test files (additional validation to be done at the model level)
  def process_test_form(assignment, params)

    # Hash for storing new and updated test files
    updated_files = {}

    # Retrieve all test file entries
    testfiles = params[:assignment][:test_files_attributes]

    # First check for duplicate filenames:
    filename_array = []
    testfiles.values.each do |tfile|
      if tfile['filename'].respond_to?(:original_filename)
        fname = tfile['filename'].original_filename
        # If this is a duplicate filename, raise error and return
        if !filename_array.include?(fname)
          filename_array << fname
        else
          raise I18n.t("automated_tests.duplicate_filename") + fname
        end
      end
    end

    # Filter out files that need to be created and updated:
    testfiles.each_key do |key|

      tfile = testfiles[key]

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
    assignment.enable_test = params[:assignment][:enable_test]
    num_tokens = params[:assignment][:tokens_per_day]
    if num_tokens
      assignment.tokens_per_day = num_tokens
    end

    return assignment
  end

end