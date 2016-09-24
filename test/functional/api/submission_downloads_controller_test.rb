require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper')
require File.join(File.dirname(__FILE__), '..', 'authenticated_controller_test')
require 'shoulda'
require 'base64'
require 'stringio'

class Api::SubmissionDownloadsControllerTest < ActionController::TestCase

  # Testing unauthenticated requests
  context 'An unauthenticated request to submission_downloads' do
    setup do
      # Set garbage HTTP header
      @request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      @request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    context '/index' do
      setup do
        get 'index', assignment_id: '1', group_id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/show' do
      setup do
        get 'show', assignment_id: '1', group_id: '1', id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/create' do
      setup do
        post 'create', assignment_id: '1', group_id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/update' do
      setup do
        put 'update', assignment_id: '1', group_id: '1', id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end

    context '/destroy' do
      setup do
        delete 'destroy', assignment_id: '1', group_id: '1', id: '1'
      end

      should 'fail to authenticate the GET request' do
        assert_response 403
      end
    end
  end

  # Testing authenticated requests
  context 'An authenticated request to submission_downloads' do
    setup do

      # Create admin from blueprints
      @admin = Admin.make
      @admin.reset_api_key
      base_encoded_md5 = @admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
      @request.env['HTTP_ACCEPT'] = 'application/xml'

      # Default XML elements displayed
      @default_xml = %w(id group-name created-at updated-at first-name
                        last-name user-name membership-status
                        student-memberships)
    end

    # Testing GET api/assignments/:assignment_id/groups/:group_id/submission_downloads
    context 'testing index function' do
      # Create students, groupings, assignments, etc for testing
      # Generates files, uploads them to the repo, and creates a submission as well
      setup do
        @assignment = Assignment.make(allow_web_submits: true, group_min: 1)
        @assignment2 = Assignment.make

        @group = Group.make
        @student = Student.make
        @grouping = Grouping.make(group: @group, assignment: @assignment)
        @membership = StudentMembership.make(user: @student,
          membership_status: 'inviter', grouping: @grouping)
        @student = @membership.user

        # Upload the two java files for testing
        @file1_name = 'Shapes.java'
        @file2_name = 'TestShapes.java'

        file1 = fixture_file_upload(File.join('files', @file1_name), 'text/java')
        file2 = fixture_file_upload(File.join('files', @file2_name), 'text/java')

        @file1_content = IO.read(file1.path)
        @file2_content = IO.read(file2.path)

        # Simulate app/controllers/submission_controller.rb#update_files
        # in order to add file1 and file2 to the repo
        @grouping.group.access_repo do |repo|
          assignment_folder = File.join(@assignment.repository_folder, '/')
          # Define file paths to retrieve entries later on
          @file1_path = assignment_folder + @file1_name
          @file2_path = assignment_folder + @file2_name
          new_files = [file1, file2]
          txn = repo.get_transaction(@student.user_name)
          new_files.each do |file_object|
            file_object.rewind
            txn.add(File.join(assignment_folder,
              file_object.original_filename),
              file_object.read, file_object.content_type)
          end
          repo.commit(txn)
          # Generate submission
          Submission.generate_new_submission(@grouping, repo.get_latest_revision)
        end
      end

      context '/index' do
        should "return a zip containing the two files if filename isn't used" do
          get 'index', assignment_id: @assignment.id.to_s, group_id:
            @group.id.to_s
          output = StringIO.new
          output.binmode
          output << @response.body
          File.open('tmp/sub_test.zip', 'wb') {|f| f.write(output.string)}
          Zip::File.open('tmp/sub_test.zip') do |zipfile|
            assert_not_nil zipfile.find_entry(@file1_path)
            assert_not_nil zipfile.find_entry(@file2_path)
            assert_equal(@file1_content, zipfile.read(@file1_path))
            assert_equal(@file2_content, zipfile.read(@file2_path))
          end
        end

        should 'return the requested file if filename is used' do
          get 'index', assignment_id: @assignment.id.to_s, group_id:
            @group.id.to_s, filename: @file1_name
          assert_response(:success)
          assert_equal(@file1_content, @response.body)
        end

        should "return a 422 if the file doesn't exist" do
          get 'index', assignment_id: @assignment.id.to_s, group_id:
            @group.id.to_s, filename: 'invalid_file_name'
          assert_response 422
        end

        should "return a 404 if the group doesn't exist" do
          get 'index', assignment_id: @assignment.id.to_s, group_id: '9999'
          assert_response 404
        end

        should "return a 404 if the assignment doesn't exist" do
          get 'index', assignment_id: '9999', group_id: @group.id.to_s
          assert_response 404
        end

        should "return a 404 if a submission doesn't exist" do
          get 'index', assignment_id: @assignment2.id.to_s, group_id:
            @group.id.to_s
          assert_response 404
        end
      end

      # Make sure the other routes don't work
      context "testing that the other routes don't exist" do
        should "show that 'show' doesn't exist" do
          get 'show', assignment_id: '1', group_id: '1', id: '1'
          assert_response :missing
        end

        should "show that create doesn't exist" do
          post 'create', assignment_id: '1', group_id: '1'
          assert_response :missing
        end

        should "show that update doesn't exist" do
          put 'update', assignment_id: '1', group_id: '1', id: '1'
          assert_response :missing
        end

        should "show that delete doesn't exist" do
          delete 'update', assignment_id: '1', group_id: '1', id: '1'
          assert_response :missing
        end
      end

    end
  end
end
