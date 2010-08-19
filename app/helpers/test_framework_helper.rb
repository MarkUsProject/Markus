# Helper methods for Testing Framework forms
module TestFrameworkHelper

  def add_test_file_link(name, form)
    link_to_function name do |page|
      test_file = render(:partial => 'test_file', :locals => {:form => form, :test_file => TestFile.new, :file_type => "test"})
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_file_id = new Date().getTime();
          $('test_files').insert({bottom: "#{ escape_javascript test_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_file_id) });
          $('assignment_test_files_' + new_test_file_id + '_filename').focus();
        } else {
          alert("#{I18n.t("test_framework.add_test_file_alert")}");
        }
      }
    end
  end

  def add_lib_file_link(name, form)
    link_to_function name do |page|
      test_file = render(:partial => 'test_file', :locals => {:form => form, :test_file => TestFile.new, :file_type => "lib"})
      page << %{
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_file_id = new Date().getTime();
          $('lib_files').insert({bottom: "#{ escape_javascript test_file }".replace(/(attributes_\\d+|\\[\\d+\\])/g, new_test_file_id) });
          $('assignment_test_files_' + new_test_file_id + '_filename').focus();
        } else {
          alert("#{I18n.t("test_framework.add_lib_file_alert")}");
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
      @ant_build_file.save(false)

      @ant_build_prop = TestFile.new
      @ant_build_prop.assignment = assignment
      @ant_build_prop.filetype = 'build.properties'
      @ant_build_prop.filename = 'tempbuild.properties' # temporary placeholder for now
      @ant_build_prop.save(false)

      # Setup Testing Framework repository
      test_dir = File.join(MarkusConfigurator.markus_config_test_framework_repository, assignment.short_identifier)
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
          raise I18n.t("test_framework.duplicate_filename") + fname
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
