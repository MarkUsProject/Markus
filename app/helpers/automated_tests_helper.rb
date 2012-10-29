require 'libxml'
require 'open3'

# Helper methods for Testing Framework forms
module AutomatedTestsHelper
  include LibXML

  def enqueue_test()
  end

  # Verify the user has the permission to run the tests - admin
  # and graders always have the permission, while student has to
  # belong to the group and has >0 tokens.
  def has_permission?()
    if @current_user.admin?
      return true
    elsif @current_user.ta?
      return true
    elsif @current_user.student?
      # Make sure student belongs to this group
      if not @current_user.accepted_groupings.include?(@grouping)
        return false
      end
      t = @grouping.token
      if t == nil
        raise I18n.t("automated_tests.missing_tokens")
      end
      if t.tokens > 0
        t.decrease_tokens
        return true
      else
        return false
      end
    end
  end

  # Verify that the system has all the files and information in order to
  # run the test.
  def files_available?()
    #code stub
    return true
  end

  # From a list of test servers, choose the next available server
  # using round-robin. Keep looking for available server until
  # one is found.
  # TODO: set timeout and return error if no server is available
  def choose_test_server()
    # code stub
    return 1
  end

  # Launch the test on the test server by scp files to the server
  # and run the script.
  # This function returns two values: first one is the output from
  # stdout or stderr, depending on whether the execution passed or
  # had error; the second one is a boolean variable, true => execution
  # passeed, false => error occurred.
  def launch_test(server_id, group, assignment)
    # Get src_dir
    src_dir = "${HOME}/workspace_aptana/Markus/data/dev/automated_tests/group_0017/a7"

    # Get test_dir
    test_dir = "${HOME}/workspace_aptana/Markus/data/dev/automated_tests/a7"
    #test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)

    # Get the account and address of the server
    server_account = "localtest"
    server_address = "scspc328.cs.uwaterloo.ca"

    # Get the directory and name of the script
    script_dir = "/home/#{server_account}/testrunner"
    script_name = "run.sh"

    # Get dest_dir of the files
    dest_dir = "/home/#{server_account}/testrunner/all"

    # Remove everything in dest_dir
    stdout, stderr, status = Open3.capture3("ssh #{server_account}@#{server_address} rm -rf #{dest_dir}")
    if !(status.success?)
      return [stderr, false]
    end

    # Securely copy files to dest_dir
    stdout, stderr, status = Open3.capture3("scp -p -r #{src_dir} #{server_account}@#{server_address}:#{dest_dir}")
    if !(status.success?)
      return [stderr, false]
    end
    stdout, stderr, status = Open3.capture3("scp -p -r #{test_dir} #{server_account}@#{server_address}:#{dest_dir}")
    if !(status.success?)
      return [stderr, false]
    end

    # Run script
    stdout, stderr, status = Open3.capture3("ssh #{server_account}@#{server_address} #{script_dir}/#{script_name}")
    if !(status.success?)
      return [stderr, false]
    else
      return [stdout, true]
    end

  end

  def result_available?()
  end

  def process_result(results_xml)
    test = AutomatedTests.new
    results_xml = results_xml ||
      File.read(RAILS_ROOT + "/automated-tests-files/test.xml")
    parser = XML::Parser.string(results_xml)
    doc = parser.parse

    # get assignment_id
    assignment_node = doc.find_first("/test/assignment_id")
    if not assignment_node or assignment_node.empty?
      raise "Test result does not have assignment id"
    else
      test.assignment_id = assignment_node.content
    end

    # get test_script_id
    test_script_node = doc.find_first("/test/test_script_id")
    if not test_script_node or test_script_node.empty?
      raise "Test result does not have test_script id"
    else
      test.test_script_id = test_script_node.content
    end

    # get group id
    group_id_node = doc.find_first("/test/group_id")
    if not group_id_node or group_id_node.empty?
      raise "Test result has no group id"
    else
      test.group_id = group_id_node.content
    end

    # get result: pass, fail, or error
    result_node = doc.find_first("/test/result")
    if not result_node or result_node.empty?
      raise "Test result has no result"
    else
      if result_node.content != "pass" and result_node.content != "fail" and
         result_node.content != "error"
        raise "invalid value for test result. Should be pass, fail or error"
      else
        test.result = result_node.content
      end
    end

    # get markus earned
    marks_earned_node = doc.find_first("/test/marks_earned")
    if not marks_earned_node or marks_earned_node.empty?
      raise "Test result has no marks earned"
    else
      test.marks_earned = marks_earned_node.content
    end

    # get input
    input_node = doc.find_first("/test/input")
    if not input_node or input_node.empty?
      raise "Test result has no input"
    else
      test.input = input_node.content
    end

    # get expected_output
    expected_output_node = doc.find_first("/test/expected_output")
    if not expected_output_node or expected_output_node.empty?
      raise "Test result has no expected_output"
    else
      test.expected_output = expected_output_node.content
    end

    # get actual_output
    actual_output_node = doc.find_first("/test/actual_output")
    if not actual_output_node or actual_output_node.empty?
      raise "Test result has no actual_output"
    else
      test.actual_output = actual_output_node.content
    end

    test.save
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
      test_script = render(:partial => 'test_script_upload',
                         :locals => {:form => form,
                                     :test_script => TestScript.new })
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_script_id = new Date().getTime();
          $('test_script_files').insert({bottom: "#{ escape_javascript test_script }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_script_id) });
          $('assignment_test_script_' + new_test_script_id + '_filename').focus();
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
                                     :test_support_file => TestSupportFile.new,
                                     :file_type => "testfile"})
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_support_file_id = new Date().getTime();
          $('test_support_files').insert({bottom: "#{ escape_javascript test_support_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_support_file_id) });
          $('assignment_test_support_file_' + new_test_support_file_id + '_filename').focus();
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

  # Verify tests can be executed
  def can_run_test?()
    if @current_user.admin?
      return true
    elsif @current_user.ta?
      return true
    elsif @current_user.student?
      # Make sure student belongs to this group
      if not @current_user.accepted_groupings.include?(@grouping)
        return false
      end
      t = @grouping.token
      if t == nil
        raise I18n.t("automated_tests.missing_tokens")
      end
      if t.tokens > 0
        t.decrease_tokens
        return true
      else
        return false
      end
    end
  end

end