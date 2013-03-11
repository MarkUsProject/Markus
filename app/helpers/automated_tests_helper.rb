require 'libxml'
require 'open3'

# Helper methods for Testing Framework forms
module AutomatedTestsHelper
  include LibXML

  # This is the waiting list for automated testing. Once a test is requested,
  # it is enqueued and it is waiting for execution. Resque manages this queue.
  @queue = :test_waiting_list

  # This is the calling interface to request a test run. 
  def AutomatedTestsHelper.request_a_test_run(submission_id, call_on, current_user)
    @current_user = current_user
    @submission = Submission.find(submission_id)
    @grouping = @submission.grouping
    @assignment = @grouping.assignment
    @group = @grouping.group
    
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)
    export_group_repo(@group, @repo_dir)
                              
    @list_run_scripts = scripts_to_run(@assignment, call_on)
    
    async_test_request(submission_id, call_on)
  end
  
  # Delete repository directory
  def self.delete_repo(repo_dir)
    # Delete student's assignment repository if it already exists
    if (File.exists?(repo_dir))
      FileUtils.rm_rf(repo_dir)
    end
  end

  # Export group repository for testing. Students' submitted files
  # are stored in the group svn repository. They must be exported
  # before copying to the test server.
  def self.export_group_repo(group, repo_dir)
    # Create the automated test repository
    if !(File.exists?(MarkusConfigurator.markus_config_automated_tests_repository))
      FileUtils.mkdir(MarkusConfigurator.markus_config_automated_tests_repository)
    end

    # Delete student's assignment repository if it already exists
    delete_repo(repo_dir)

    # export
    return group.repo.export(repo_dir)
    rescue Exception => e
      return "#{e.message}"
  end

  # Find the list of test scripts to run the test. Return the list of
  # test scripts in the order specified by seq_num (running order)
  def self.scripts_to_run(assignment, call_on)
    # Find all the test scripts of the current assignment
    all_scripts = TestScript.find_all_by_assignment_id(assignment.id)

    list_run_scripts = Array.new

    # If the test run is requested at collection (by Admin or TA),
    # All of the test scripts should be run.
    if call_on == "collection"
      list_run_scripts = all_scripts
    else
      # If the test run is requested at submission or upon request,
      # verify the script is allowed to run.
      all_scripts.each do |script|
        if (call_on == "submission") && script.run_on_submission
          list_run_scripts.insert(list_run_scripts.length, script)
        elsif (call_on == "request") && script.run_on_request
          list_run_scripts.insert(list_run_scripts.length, script)
        end
      end
    end

    # sort list_run_scripts using ruby's in place sorting method
    list_run_scripts.sort_by! {|script| script.seq_num}
    
    # list_run_scripts should be sorted now. Perform a check here.
    # Take this out if it causes performance issue.
    ctr = 0
    while ctr < list_run_scripts.length - 1
      if (list_run_scripts[ctr].seq_num) > (list_run_scripts[ctr+1].seq_num)
        raise "list_run_scripts is not sorted"
      end
      ctr = ctr + 1
    end

    return list_run_scripts
  end
  
  # Request an automated test. Ask Resque to enqueue a job.
  def self.async_test_request(submission_id, call_on)
    if has_permission?
      if files_available? 
        Resque.enqueue(AutomatedTestsHelper, submission_id, call_on)
      end
    end
  end

  # Verify the user has the permission to run the tests - admin
  # and graders always have the permission, while student has to
  # belong to the group, and have at least one token.
  def self.has_permission?()
    if @current_user.admin?
      return true
    elsif @current_user.ta?
      return true
    elsif @current_user.student?
      # Make sure student belongs to this group
      if not @current_user.accepted_groupings.include?(@grouping)
        # TODO: show the error to user instead of raising a runtime error
        raise I18n.t("automated_tests.not_belong_to_group")
      end
      t = @grouping.token
      if t == nil
        raise I18n.t("automated_tests.missing_tokens")
      end
      if t.tokens > 0
        t.decrease_tokens
        return true
      else
        # TODO: show the error to user instead of raising a runtime error
        raise I18n.t("automated_tests.missing_tokens")
      end
    end
  end
  
  # Verify that MarkUs has some files to run the test.
  # Note: this does not guarantee all required files are presented.
  # Instead, it checks if there is at least one test script and
  # source files are successfully exported.
  def self.files_available?()
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @assignment.short_identifier)
    src_dir = @repo_dir

    if !(File.exists?(test_dir))
      # TODO: show the error to user instead of raising a runtime error
      raise I18n.t("automated_tests.test_files_unavailable")
    elsif !(File.exists?(src_dir))
      # TODO: show the error to user instead of raising a runtime error
      raise I18n.t("automated_tests.source_files_unavailable")
    end

    scripts = TestScript.find_all_by_assignment_id(@assignment.id)
    if scripts.empty?
      # TODO: show the error to user instead of raising a runtime error
      raise I18n.t("automated_tests.test_files_unavailable")
    end

    return true
  end

  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  def self.perform(submission_id, call_on) 
    # Pick a server, launch the Test Runner and wait for the result
    # Then store the result into the database
  
    @submission = Submission.find(submission_id)
    @grouping = @submission.grouping
    @assignment = @grouping.assignment
    @group = @grouping.group
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)

    @list_of_servers = MarkusConfigurator.markus_ate_test_server_hosts.split(' ')
    
    while true
      @test_server_id = choose_test_server()
      if @test_server_id >= 0 
        break
      else
        sleep 5               # if no server is available, sleep for 5 second before it checks again
      end  
    end

    result, status = launch_test(@test_server_id, @assignment, @repo_dir, call_on)
    
    if !status
      # TODO: handle this error better
      raise "error"
    else
      process_result(result, submission_id, @assignment.id)
    end

  end

  # From a list of test servers, choose the next available server
  # using round-robin. Return the id of the server, and return -1
  # if no server is available.
  # TODO: keep track of the max num of tests running on a server
  def self.choose_test_server()

    if (defined? @last_server) && MarkusConfigurator.automated_testing_engine_on?
      # find the index of the last server, and return the next index
      @last_server = (@last_server + 1) % MarkusConfigurator.markus_ate_num_test_servers
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
  def self.launch_test(server_id, assignment, repo_dir, call_on)
    # Get src_dir
    src_dir = File.join(repo_dir, assignment.repository_folder)

    # Get test_dir
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.repository_folder)

    # Get the name of the test server
    server = @list_of_servers[server_id]

    # Get the directory and name of the test runner script
    test_runner = MarkusConfigurator.markus_ate_test_runner_script_name

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
    stdout, stderr, status = Open3.capture3("scp -p -r '#{src_dir}'/* #{server}:#{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end
    stdout, stderr, status = Open3.capture3("scp -p -r '#{test_dir}'/* #{server}:#{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end
    stdout, stderr, status = Open3.capture3("ssh #{server} cp #{test_runner} #{run_dir}")
    if !(status.success?)
      return [stderr, false]
    end

    # Find the test scripts for this test run, and parse the argument list
    list_run_scripts = scripts_to_run(assignment, call_on)
    arg_list = ""
    list_run_scripts.each do |script|
      arg_list = arg_list + "#{script.script_name} #{script.halts_testing} "
    end
    
    # Run script
    test_runner_name = File.basename(test_runner)
    stdout, stderr, status = Open3.capture3("ssh #{server} \"cd #{run_dir}; ruby #{test_runner_name} #{arg_list}\"")
    if !(status.success?)
      return [stderr, false]
    else
      return [stdout, true]
    end
    
  end

  def self.process_result(result, submission_id, assignment_id)
    parser = XML::Parser.string(result)

    # parse the xml doc
    doc = parser.parse

    # find all the test_script nodes and loop over them
    test_scripts = doc.find('/testrun/test_script')
    test_scripts.each do |s_node|
      script_result = TestScriptResult.new
      script_result.submission_id = submission_id
      script_marks_earned = 0    # cumulate the marks_earn in this script
      
      # find the script name and save it
      script_name_nodes = s_node.find('./script_name')
      if script_name_nodes.length != 1
        # FIXME: better error message is required (use locale)
        raise "None or more than one test script name is found in one test_script tag."
      else
        script_name = script_name_nodes[0].content
      end
      
      # Find all the test scripts with this script_name.
      # There should be one and only one record - raise exception if not
      test_script_array = TestScript.find_all_by_assignment_id_and_script_name(assignment_id, script_name)
      if test_script_array.length != 1
        # FIXME: better error message is required (use locale)
        raise "None or more than one test script is found for script name " + script_name
      else
        test_script = test_script_array[0]
      end

      script_result.test_script_id = test_script.id

      # find all the test nodes and loop over them
      tests = s_node.find('./test')
      tests.each do |t_node|
        test_result = TestResult.new
        test_result.submission_id = submission_id
        test_result.test_script_id = test_script.id
        # give default values
        test_result.name = 'no name is given'
        test_result.completion_status = 'error'
        test_result.input_description = ''
        test_result.expected_output = ''
        test_result.actual_output = ''
        test_result.marks_earned = 0
        
        t_node.each_element do |child|
          if child.name == 'name'
            test_result.name = child.content
          elsif child.name == 'status'
            test_result.completion_status = child.content.downcase
          elsif child.name == 'input'
            test_result.input_description = child.content
          elsif child.name == 'expected'
            test_result.expected_output = child.content
          elsif child.name == 'actual'
            test_result.actual_output = child.content
          elsif child.name == 'marks_earned'
            test_result.marks_earned = child.content
            script_marks_earned += child.content.to_i
          else
            # FIXME: better error message is required (use locale)
            raise "Error: malformed xml from test runner. Unclaimed tag: " + child.name
          end
        end
        
        # save to database
        test_result.save
      end
      
      # if a marks_earned tag exists under test_script tag, get the value;
      # otherwise, use the cumulative marks earned from all unit tests
      script_marks_earned_nodes = s_node.find('./marks_earned')
      if script_marks_earned_nodes.length == 1
        script_result.marks_earned = script_marks_earned_nodes[0].content.to_i
      else
        script_result.marks_earned = script_marks_earned
      end
      
      # save to database
      script_result.save
      
    end
  end

  # Create a repository for the test scripts, and a placeholder script
  def create_test_scripts(assignment)

    # Setup Testing Framework repository
    test_dir = File.join(
                MarkusConfigurator.markus_config_automated_tests_repository,
                assignment.short_identifier)
    FileUtils.makedirs(test_dir)

    assignment.reload
  end

  # Create a repository for the test scripts and test support files
  # if it does not exist
  def create_test_repo(assignment)
    # Create the automated test repository
    if !(File.exists?(MarkusConfigurator.markus_config_automated_tests_repository))
      FileUtils.mkdir(MarkusConfigurator.markus_config_automated_tests_repository)
    end
    
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)
    if !(File.exists?(test_dir))
      FileUtils.mkdir(test_dir)
    end
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
          $('test_scripts').insert({bottom: "#{ escape_javascript test_script }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_script_id) });
          $('test_script_options').insert({bottom: "#{ escape_javascript test_script_options }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_script_id) });
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

  # Process new and updated test files (additional validation to be done at the model level)
  def process_test_form(assignment, params)

    # Hash for storing new and updated test files
    updated_script_files = {}
    updated_support_files = {}

    # Array for checking duplicate file names
    file_name_array = []
    
    #add existing scripts names
    params.each {|key, value| if(key[/test_script_\d+/] != nil) then file_name_array << value end}
    
    # Retrieve all test scripts
    testscripts = params[:assignment][:test_scripts_attributes]

    # First check for duplicate script names in test scripts
    if !testscripts.nil?
      testscripts.values.each do |tfile|
        if tfile['script_name'].respond_to?(:original_filename)
          fname = tfile['script_name'].original_filename
          # If this is a duplicate script name, raise error and return
          if !file_name_array.include?(fname)
            file_name_array << fname
          else
            raise I18n.t("automated_tests.duplicate_filename") + fname
          end
        end
      end
    end

    # Retrieve all test support files
    testsupporters = params[:assignment][:test_support_files_attributes]

    # Now check for duplicate file names in test support files
    if !testsupporters.nil?
      testsupporters.values.each do |tfile|
        if tfile['file_name'].respond_to?(:original_filename)
          fname = tfile['file_name'].original_filename
          # If this is a duplicate file name, raise error and return
          if !file_name_array.include?(fname)
            file_name_array << fname
          else
            raise I18n.t("automated_tests.duplicate_filename") + fname
          end
        end
      end
    end

    # Filter out script files that need to be created and updated
    if !testscripts.nil?
      testscripts.each_key do |key|
  
        tfile = testscripts[key]
  
        # Check to see if this is an update or a new file:
        # - If 'id' exists, this is an update
        # - If 'id' does not exist, this is a new test file
        tf_id = tfile['id']
  
        # If only the 'id' exists in the hash, other attributes were not updated so we skip this entry.
        # Otherwise, this test file possibly requires an update
        if tf_id != nil && tfile.size > 1
  
          # Find existing test file to update
          @existing_testscript = TestScript.find_by_id(tf_id)
          if @existing_testscript
            # Store test file for any possible updating
            updated_script_files[key] = tfile
          end
        end
  
        # Test file needs to be created since record doesn't exist yet
        if tf_id.nil? && tfile['script_name']
          updated_script_files[key] = tfile
        end
      end
    end

    # Filter out test support files that need to be created and updated
    if !testsupporters.nil?
      testsupporters.each_key do |key|
  
        tfile = testsupporters[key]
  
        # Check to see if this is an update or a new file:
        # - If 'id' exists, this is an update
        # - If 'id' does not exist, this is a new test file
        tf_id = tfile['id']
  
        # If only the 'id' exists in the hash, other attributes were not updated so we skip this entry.
        # Otherwise, this test file possibly requires an update
        if tf_id != nil && tfile.size > 1
  
          # Find existing test file to update
          @existing_testsupport = TestSupportFile.find_by_id(tf_id)
          if @existing_testsupport
            # Store test file for any possible updating
            updated_support_files[key] = tfile
          end
        end
  
        # Test file needs to be created since record doesn't exist yet
        if tf_id.nil? && tfile['file_name']
          updated_support_files[key] = tfile
        end
      end
    end

    # Update test file attributes
    assignment.test_scripts_attributes = updated_script_files
    assignment.test_support_files_attributes = updated_support_files

    # Update assignment enable_test and tokens_per_day attributes
    assignment.enable_test = params[:assignment][:enable_test]
    num_tokens = params[:assignment][:tokens_per_day]
    if num_tokens
      assignment.tokens_per_day = num_tokens
    end

    return assignment
  end

end