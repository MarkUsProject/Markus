require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'
require 'mocha/setup'

class ResultsControllerTest < AuthenticatedControllerTest

  def teardown
      destroy_repos
  end

  SAMPLE_ERR_MSG = 'sample error message'

  should 'recognize routes' do
    assert_recognizes({:controller => 'results',
                       :action => 'update_mark',
                       :assignment_id => '1',
                       :submission_id => '1'},
                      {:path => 'assignments/1/submissions/1/results/update_mark',
                       :method => :post})
  end

  context 'A user' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    should 'be redirected from edit' do
      get :edit,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to get the next_grouping' do
      get :next_grouping,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to set_released to student' do
      get :set_released_to_students,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to update marking state' do
      get :update_marking_state,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1,
          :value => 1
      assert_response :redirect
    end

    should 'not be able to update overall comment' do
      get :update_overall_comment,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to update overall remark comment' do
      get :update_overall_remark_comment,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1

      assert_response :redirect
    end

    should 'not be able to update remark request' do
      get :update_remark_request,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to cancel remark request' do
      get :cancel_remark_request,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to download a file' do
      get :download,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1,
          :select_file_id => 1
      assert_response :redirect
    end

    should 'not be able to get codeviewer' do
      get :codeviewer,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1,
          :focus_line => 1
      assert_response :redirect
    end

    should 'not be able to update mark' do
      get :update_mark,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1,
          :mark_id => 1,
          :mark => 0
      assert_response :redirect
    end

    should 'not be able to view marks' do
      get :view_marks,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end

    should 'not be able to add extra mark' do
      get :add_extra_mark,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1,
          :extra_mark => 1
      assert_response :redirect
    end

    should 'not be able to remove extra marks' do
      get :remove_extra_mark,
          :assignment_id => 1,
          :submission_id => 1,
          :id => 1
      assert_response :redirect
    end
  end # unauthenticated and unauthorized user doing

  context 'A student' do

    {:setup_student_flexible => 'flexible',
     :setup_student_rubric => 'rubric'}.each do |setup_method, scheme_type|

      context "in an assignment with #{scheme_type} scheme doing a" do
        setup do
          @student = Student.make
          @assignment = Assignment.make(:marking_scheme_type => scheme_type)
          @grouping = Grouping.make(:assignment => @assignment)
          StudentMembership.make(
              :grouping => @grouping,
              :user => @student,
              :membership_status => StudentMembership::STATUSES[:inviter])
          @submission = Submission.make(:grouping => @grouping)
          @result = @grouping.submissions.first.get_latest_result
        end

        should 'not be able to get edit' do
          get_as @student,
                 :edit,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => @result.id
          assert_response :missing
          assert render_template 404
        end

        should 'not be able to get next_grouping' do
          get_as @student,
                 :next_grouping,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => @grouping.id
          assert_response :missing
          assert render_template 404
        end

        should 'GET on :set_released_to_student' do
          get_as @student,
                 :set_released_to_students,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => @result.id
          assert_response :missing
          assert render_template 404
        end

        should 'GET on :update_marking_state' do
          get_as @student,
                  :update_marking_state,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :value => 1
          assert_response :missing
          assert render_template 404
        end

        should 'GET on :update_overall_comment' do
          @new_comment = 'a changed overall comment!'
          get_as @student,
                  :update_overall_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @new_comment}
          assert_response :missing
          assert render_template 404
          @result.reload
          assert_not_equal @result.overall_comment, @new_comment
        end

        should 'POST on :update_overall_comment' do
          @new_comment = 'a changed overall comment!'
          post_as @student,
                  :update_overall_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @new_comment}
          assert_response :missing
          assert render_template 404
          @result.reload
          assert_not_equal @result.overall_comment, @new_comment
        end

        should 'GET on :update_overall_remark_comment' do
          @new_comment = 'a changed overall remark comment!'
          get_as @student,
                  :update_overall_remark_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @new_comment}
          assert_response :missing
          assert render_template 404
          @result.reload
          assert_not_equal @result.overall_comment, @new_comment
        end

        should 'POST on :update_overall_remark_comment' do
          @new_comment = 'a changed overall remark comment!'
          post_as @student,
                  :update_overall_remark_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @new_comment}
          assert_response :missing
          assert render_template 404
          @result.reload
          assert_not_equal @result.overall_comment, @new_comment
        end

        context 'GET on :download' do
          setup do
            @file = SubmissionFile.new
          end

          context 'without file error' do

            should 'with permissions to download the file' do
              @file.expects(:filename).once.returns('filename')
              @file.expects(:is_supported_image?).once.returns(false)
              @file.expects(:is_pdf?).once.returns(false)
              @file.expects(:retrieve_file).returns('file content')
              ResultsController.any_instance.stubs(
                    :authorized_to_download?).once.returns(true)
              SubmissionFile.stubs(:find).once.returns(@file)
              get_as @student,
                     :download,
                     :assignment_id => 1,
                     :submission_id => 1,
                     :select_file_id => 1,
                     :id => 1

              assert_equal true, flash.empty?
              assert_equal response.header['Content-Type'], 'application/octet-stream'
              assert_response :success
              assert_equal 'file content', @response.body
            end  # -- with permissions to download the file

            should 'without permissions to download the file' do
              ResultsController.any_instance.stubs(
                  :authorized_to_download?).once.returns(false)
              get_as @student,
                     :download,
                     :assignment_id => 1,
                     :submission_id => 1,
                     :select_file_id => 1,
                     :id => 1

              assert_equal true, flash.empty?
              assert_response :missing
              assert render_template 404
            end  # -- without permissions to download the file
          end # -- without file error

          should 'be able to retrieve_file with file error' do
            @file.expects(:submission).twice.returns(@result.submission)

            @file.expects(
                :retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
            ResultsController.any_instance.stubs(
                        :authorized_to_download?).once.returns(true)
            SubmissionFile.stubs(:find).once.returns(@file)

            get_as @student,
                  :download,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => 1,
                  :select_file_id => 1

            assert_equal flash[:file_download_error], SAMPLE_ERR_MSG
            assert_response :redirect
          end

          should 'with supported image to be displayed inside browser' do
            @file.expects(:filename).once.returns('filename.supported_image')
            @file.expects(:is_supported_image?).once.returns(true)
            @file.expects(:retrieve_file).returns('file content')
            ResultsController.any_instance.stubs(
                :authorized_to_download?).once.returns(true)
            SubmissionFile.stubs(:find).once.returns(@file)

            get_as @student,
                  :download,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :select_file_id => 1,
                  :id => 1,
                  :show_in_browser => true
            assert_equal true, flash.empty?
            assert_equal response.header['Content-Type'], 'image'
            assert_response :success
            assert_equal 'file content', @response.body
          end

          should 'with annotations included' do
            @file.expects(:filename).once.returns('filename')
            @file.expects(:is_supported_image?).once.returns(false)
            @file.expects(:is_pdf?).once.returns(false)
            @file.expects(:retrieve_file).returns('file content')
            ResultsController.any_instance.stubs(:authorized_to_download?).once.returns(true)
            SubmissionFile.stubs(:find).once.returns(@file)

            get_as @student,
                  :download,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :select_file_id => 1,
                  :id => 1,
                  :include_annotations => true
            assert_equal true, flash.empty?
            assert_equal response.header['Content-Type'], 'application/octet-stream'
            assert_response :success
            assert_equal 'file content', @response.body
          end
        end

        context 'GET on :codeviewer' do
          setup do
            SubmissionFile.make(:submission => @submission)
            @submission_file = @result.submission.submission_files.first
          end

          should 'and the student has no access to that file' do
            @no_access_submission_file = SubmissionFile.make
            get_as @student,
                    :codeviewer,
                    :assignment_id => @assignment.id,
                    :submission_id => 1,
                    :id => 1,
                    :submission_file_id => @no_access_submission_file.id,
                    :focus_line => 1

            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_nil assigns :file_contents
            assert_nil assigns :annots
            assert_nil assigns :all_annots
            assert render_template 'shared/_handle_error.js.erb'
            assert_response :success

            # Workaround to assert that the error message made its way to
            # the response
            r = Regexp.new(I18n.t(
                    'submission_file.error.no_access',
                    :submission_file_id => @no_access_submission_file.id))
            assert_match r, @response.body
          end

          should 'with file reading error' do
            # We simulate a file reading error.
            SubmissionFile.any_instance.expects(
              :retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
            get_as @student,
                  :codeviewer,
                  :assignment_id => @assignment.id,
                  :submission_id => 1,
                  :submission_file_id => @submission_file.id,
                  :id => 1,
                  :focus_line => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_not_nil assigns :file
            assert_not_nil assigns :result
            assert_not_nil assigns :annots
            assert_not_nil assigns :all_annots
            assert_nil assigns :file_contents
            assert_nil assigns :code_type
            assert render_template 'shared/_handle_error.js.erb'
            assert_response :success
            # Workaround to assert that the error message made its way to
            # the response
            assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
          end

          should 'without error' do
            # We don't want to access a real file.
            SubmissionFile.any_instance.expects(
              :retrieve_file).once.returns('file content')
            get_as @student,
                  :codeviewer,
                  :assignment_id => @assignment.id,
                  :submission_id => 1,
                  :submission_file_id => @submission_file.id,
                  :id => 1,
                  :focus_line => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_not_nil assigns :file
            assert_not_nil assigns :result
            assert_not_nil assigns :annots
            assert_not_nil assigns :all_annots
            assert_not_nil assigns :file_contents
            assert_not_nil assigns :code_type
            assert render_template 'results/common/codeviewer'
            assert_response :success
          end
        end

        should 'GET on :update_mark' do
          get_as @student,
                 :update_mark,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :mark_id => 1,
                 :mark => 0
          assert_response :missing
          assert render_template 404
        end

        context 'GET on :view_marks' do
          should 'and his grouping has no submission' do
            Grouping.any_instance.expects(:has_submission?).once.returns(false)
            get_as @student,
                   :view_marks,
                   :assignment_id => @assignment.id,
                   :submission_id => 1,
                   :id => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :grouping
            assert render_template 'results/student/no_submission'
            assert_response :success
          end

          should 'and his submission has no result' do
            Submission.any_instance.expects(:has_result?).once.returns(false)
            get_as @student,
                   :view_marks,
                   :assignment_id => @assignment.id,
                   :submission_id => 1,
                   :id => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :grouping
            assert_not_nil assigns :submission
            assert render_template 'results/student/no_result'
            assert_response :success
          end

          should 'and the result has not been released' do
            Result.any_instance.expects(
                :released_to_students).once.returns(false)
            get_as @student,
                   :view_marks,
                   :assignment_id => @assignment.id,
                   :submission_id => 1,
                   :id => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :grouping
            assert_not_nil assigns :submission
            assert_not_nil assigns :result
            assert render_template 'results/student/no_result'
            assert_response :success
          end

          should 'and the result is available' do
            SubmissionFile.make(:submission => @submission)
            Mark.make(:result => @result)
            AnnotationCategory.make(:assignment => @assignment)
            @submission_file = @result.submission.submission_files.first
            @result.marking_state = Result::MARKING_STATES[:complete]
            @result.released_to_students = true
            @result.save

            get_as @student,
                   :view_marks,
                   :assignment_id => @assignment.id,
                   :submission_id => 1,
                   :id => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :grouping
            assert_not_nil assigns :submission
            assert_not_nil assigns :result
            assert_not_nil assigns :mark_criteria
            assert_not_nil assigns :annotation_categories
            assert_not_nil assigns :group
            assert_not_nil assigns :files
            assert_not_nil assigns :first_file
            assert_not_nil assigns :extra_marks_points
            assert_not_nil assigns :extra_marks_percentage
            assert_not_nil assigns :marks_map
            assert_response :success
            assert render_template :view_marks
          end
        end

        should 'GET on :add_extra_mark' do
          get_as @student,
                :add_extra_mark,
                :assignment_id => 1,
                :submission_id => 1,
                :id => @result.id,
                :extra_mark => 1
          assert_response :missing
          assert render_template 404
        end

        should 'GET on :remove_extra_mark' do
          get_as @student,
                 :remove_extra_mark,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => @result.id
          assert_response :missing
          assert render_template 404
        end
      end
    end
  end # An authenticated and authorized student doing a

  context 'An admin' do

    {:setup_admin_flexible => 'flexible',
     :setup_admin_rubric => 'rubric'}.each do |setup_method, scheme_type|

      context "in an assignment with #{scheme_type} scheme doing a" do
        setup do
          @admin = Admin.make
          @assignment = Assignment.make(:marking_scheme_type => scheme_type)
        end

        context 'GET on :edit' do
          context 'with 2 partial and 1 released/completed results' do
            setup do
              3.times do |time|
                g = Grouping.make(:assignment => @assignment)
                s = Submission.make(:grouping => g)
                if time == 2
                  @result = s.get_latest_result
                  @result.marking_state = Result::MARKING_STATES[:complete]
                  @result.released_to_students = true
                  @result.save
                end
              end
              @groupings = @assignment.groupings.all(:order => 'id ASC')
            end

            should 'have two separate edit forms with correct actions for' +
                   'overall comment and overall remark comment respectively' do
              # Use a released result as the original result.
              original_result = @result
              submission = original_result.submission

              # Create a remark result associated with the created submission.
              remark_result = Result.make(:submission => submission)
              submission.remark_result_id = remark_result.id
              submission.save!

              get_as @admin,
                     :edit,
                     :assignment_id => @assignment.id,
                     :submission_id => submission.id,
                     :id => remark_result.id

              path_prefix = "/en/assignments/#{@assignment.id}" +
                            "/submissions/#{submission.id}/results"
              assert_select '#overall_comment_edit form[action=' +
                            "#{path_prefix}/#{original_result.id}" +
                            '/update_overall_comment]'
              assert_select '#overall_remark_comment_edit form[action=' +
                            "#{path_prefix}/#{remark_result.id}" +
                            '/update_overall_remark_comment]'
            end

            should 'edit third result' do

              @result = @groupings[0].current_submission_used.get_latest_result
              get_as @admin,
                     :edit,
                     :assignment_id => 1,
                     :submission_id => 1,
                     :id => @result.id
              assert assigns(:next_grouping)
              next_grouping = assigns(:next_grouping)
              assert next_grouping.has_submission?
              next_result = next_grouping.current_submission_used.get_latest_result
              assert_not_nil next_result
              assert_equal next_grouping, @groupings[1]
              assert !next_result.released_to_students
              assert_nil assigns(:previous_grouping)
              assert_equal true, flash.empty?
              assert render_template :edit
              assert_response :success
            end

            should 'edit second result correctly' do
              @result = @groupings[1].current_submission_used.get_latest_result
              get_as @admin,
                     :edit,
                     :assignment_id => 1,
                     :submission_id => 1,
                     :id => @result.id

              assert assigns(:next_grouping)
              assert assigns(:previous_grouping)
              next_grouping = assigns(:next_grouping)
              previous_grouping = assigns(:previous_grouping)
              assert next_grouping.has_submission?
              assert previous_grouping.has_submission?
              next_result = next_grouping.current_submission_used.get_latest_result
              previous_result = previous_grouping.current_submission_used.get_latest_result
              assert_not_nil next_result
              assert_not_nil previous_result
              assert_equal next_grouping, @groupings[2]
              assert_equal previous_grouping, @groupings[0]
              assert next_result.released_to_students
              assert !previous_result.released_to_students

              assert_equal true, flash.empty?
              assert render_template :edit
              assert_response :success
            end

            should 'when editing third result' do

              @result = @groupings[2].current_submission_used.get_latest_result
              get_as @admin,
                     :edit,
                     :assignment_id => 1,
                     :submission_id => 1,
                     :id => @result.id

              assert_nil assigns(:next_grouping)
              assert assigns(:previous_grouping)
              previous_grouping = assigns(:previous_grouping)
              assert previous_grouping.has_submission?
              previous_result = previous_grouping.current_submission_used.get_latest_result
              assert_not_nil previous_result
              assert_equal previous_grouping, @groupings[1]
              assert !previous_result.released_to_students

              assert_equal true, flash.empty?
              assert render_template :edit
              assert_response :success
            end
          end
        end

        context 'GET on :next_grouping' do
          should 'when current grouping has submission' do
            grouping = Grouping.make
            Grouping.any_instance.stubs(:has_submission).returns(true)
            get_as @admin,
                   :next_grouping,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => grouping.id
            assert_response :redirect
          end

          should 'when current grouping has no submission' do
            grouping = Grouping.make
            Grouping.any_instance.stubs(:has_submission).returns(false)
            get_as @admin,
                   :next_grouping,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => grouping.id
            assert_response :redirect
          end
        end

        should 'GET on :set_released_to_students' do
          g = Grouping.make(:assignment => @assignment)
          s = Submission.make(:grouping => g)
          @result = s.get_latest_result
          get_as @admin,
                  :set_released_to_students,
                  :assignment_id => @assignment,
                  :submission_id => 1,
                  :id => @result.id,
                  :value => 'true'
          assert_response :success
          assert_not_nil assigns :result
        end

        context 'GET on :update_marking_state' do
          setup do
            # refresh the grade distribution - there's already a completed mark so far
            # for each rubric type, in the following grade range:
            # flexible: 6-10%
            # rubric: 21-25%
            g = Grouping.make(:assignment => @assignment)
            s = Submission.make(:grouping => g)
            @result = s.get_latest_result
            if @assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:rubric]
              Mark.make(:rubric, :result => @result)
            else
              Mark.make(:flexible, :result => @result)
            end

            @assignment.assignment_stat.refresh_grade_distribution
            @grade_distribution = @assignment.assignment_stat.grade_distribution_percentage

            # convert @grade_distribution csv to an array
            @grade_distribution = @grade_distribution.parse_csv.map{ |x| x.to_i }

            # after the call to get_as, a second result for each marking scheme type
            # will be marked as complete, a result which will be in the same grade range
            # therefore we must increment the number of groupings at the given range for
            # each marking scheme type
            if @assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:rubric]
              @grade_distribution[4] += 1
            else
              @grade_distribution[1] += 1
            end

            get_as @admin,
                   :update_marking_state,
                   {:assignment_id => @assignment.id,
                    :submission_id => 1,
                    :id => @result.id, :value => 'complete'}
          end

          should 'refresh the cached grade distribution data when the marking state is set to complete' do
            @assignment.reload
            actual_distribution = @assignment.assignment_stat.grade_distribution_percentage.parse_csv.map{ |x| x.to_i }
            assert_equal actual_distribution, @grade_distribution
            assert_not_nil assigns :result
          end
          should respond_with :success
        end

        context 'GET on :download' do
          setup do
            @file = SubmissionFile.new
          end

          should 'download without file error' do
            @file.expects(:filename).once.returns('filename')
            @file.expects(:retrieve_file).returns('file content')
            @file.expects(:is_supported_image?).once.returns(false)
            @file.expects(:is_pdf?).once.returns(false)
            SubmissionFile.stubs(:find).returns(@file)

            get_as @admin,
                   :download,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :select_file_id => 1,
                   :id => 1
            assert_equal true, flash.empty?
            assert_equal response.header['Content-Type'], 'application/octet-stream'
            assert_response :success
            assert_equal 'file content', @response.body
          end  # -- without file error

          should 'download with file error' do
            submission = Submission.make
            SubmissionFile.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
            SubmissionFile.stubs(:find).returns(@file)

            @file.expects(:submission).twice.returns(
                submission)
            get_as @admin,
                   :download,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :select_file_id => 1,
                   :id => 1

            assert_equal flash[:file_download_error], SAMPLE_ERR_MSG
            assert_response :redirect
          end  # -- with file error

          should 'with supported image to be displayed inside browser' do
            @file.expects(:filename).once.returns(
              'filename.supported_image')
            @file.expects(:retrieve_file).returns('file content')
            @file.expects(:is_supported_image?).once.returns(true)
            SubmissionFile.stubs(:find).returns(@file)

            get_as @admin,
                    :download,
                    :assignment_id => 1,
                    :submission_id => 1,
                    :id => 1,
                    :select_file_id => 1,
                    :show_in_browser => true

            assert_equal response.header['Content-Type'], 'image'
            assert_response :success
            assert_equal 'file content', @response.body
          end  # -- with supported image to be displayed in browser
        end

        context 'GET on :download_zip' do

          setup do
            @group = Group.make
            @student = Student.make
            @grouping = Grouping.make(:group => @group,
                                      :assignment => @assignment)
            @membership = StudentMembership.make(:user => @student,
                                                 :membership_status => 'inviter',
                                                 :grouping => @grouping)
            @student = @membership.user
            @file1_name = 'TestFile.java'
            @file1_content = "Some contents for TestFile.java\n"

            @group.access_repo do |repo|
              txn = repo.get_transaction('test')
              path = File.join(@assignment.repository_folder, @file1_name)
              txn.add(path, @file1_content, '')
              repo.commit(txn)

              # Generate submission
              @submission = Submission.
                  generate_new_submission(@grouping, repo.get_latest_revision)
            end
            @annotation = TextAnnotation.new
            @file = SubmissionFile.find_by_submission_id(@submission.id)
            @annotation.
                update_attributes({ :line_start => 1,
                                    :line_end => 2,
                                    :submission_file_id => @file.id,
                                    :is_remark => false,
                                    :annotation_number => @submission.
                                        annotations.count + 1
                                  })
            @annotation.annotation_text = AnnotationText.make
            @annotation.save
          end

          should 'download in zip all files with annotations' do
            get_as @admin, :download_zip,
                   :assignment_id => @assignment.id,
                   :submission_id => @submission.id,
                   :id => @submission.id,
                   :grouping_id => @grouping.id,
                   :include_annotations => 'true'

            assert_equal 'application/zip', response.header['Content-Type']
            assert_response :success
            zip_path = "tmp/#{@assignment.short_identifier}_" +
                "#{@grouping.group.group_name}_r#{@grouping.group.repo.
                    get_latest_revision.revision_number}_ann.zip"
            Zip::File.open(zip_path) do |zip_file|
              file1_path = File.join("#{@assignment.repository_folder}-" +
                                         "#{@grouping.group.repo_name}",
                                     @file1_name)
              assert_not_nil zip_file.find_entry(file1_path)
              assert_equal @file.retrieve_file(true), zip_file.read(file1_path)
            end
          end

          should 'download in zip all files without annotations' do
            get_as @admin, :download_zip,
                   :assignment_id => @assignment.id,
                   :submission_id => @submission.id,
                   :id => @submission.id,
                   :grouping_id => @grouping.id,
                   :include_annotations => 'false'

            assert_equal 'application/zip', response.header['Content-Type']
            assert_response :success
            zip_path = "tmp/#{@assignment.short_identifier}_" +
                "#{@grouping.group.group_name}_r#{@grouping.group.repo.
                    get_latest_revision.revision_number}.zip"
            Zip::File.open(zip_path) do |zip_file|
              file1_path = File.join("#{@assignment.repository_folder}-" +
                                         "#{@grouping.group.repo_name}",
                                     @file1_name)
              assert_not_nil zip_file.find_entry(file1_path)
              assert_equal @file.retrieve_file, zip_file.read(file1_path)
            end
          end
        end

        context 'GET on :codeviewer' do
          setup do
            g = Grouping.make(:assignment => @assignment)
            @submission = Submission.make(:grouping => g)
            @file = SubmissionFile.make(:submission => @submission)
            annotation = Annotation.new
            @file.expects(:annotations).once.returns(annotation)
            SubmissionFile.stubs(:find).returns(@file)
          end

          should 'without file error' do
            @file.expects(:get_file_type).once.returns('txt')
            SubmissionFile.any_instance.expects(:retrieve_file).once.returns('file content')
            get_as @admin,
                    :codeviewer,
                    :assignment_id => @assignment.id,
                    :submission_id => 1,
                    :id => 1,
                    :focus_line => 1,
                    :submission_file_id => @file.id

            assert_equal true, flash.empty?
            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_not_nil assigns :file
            assert_not_nil assigns :result
            assert_not_nil assigns :annots
            assert_not_nil assigns :all_annots
            assert_not_nil assigns :file_contents
            assert_not_nil assigns :code_type
            assert render_template 'results/common/codeviewer'
            assert_response :success
          end  # -- without file error

          should 'with file error' do
            SubmissionFile.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
            get_as @admin,
                   :codeviewer,
                   :assignment_id => @assignment.id,
                   :submission_id => 1,
                   :id => 1,
                   :focus_line => 1,
                   :submission_file_id => @file.id

            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_not_nil assigns :file
            assert_not_nil assigns :result
            assert_not_nil assigns :annots
            assert_not_nil assigns :all_annots
            assert_nil assigns :file_contents
            assert_nil assigns :code_type
            assert render_template 'shared/_handle_error.js.erb'
            assert_response :success
            # Workaround to assert that the error message made its way to the
            # response
            assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
          end  # --with file error
        end

        context 'GET on :update_mark' do
          setup do
            g = Grouping.make(:assignment => @assignment)
            @submission = Submission.make(:grouping => g)

            @mark = Mark.make(:result => @submission.get_latest_result)
          end

          should 'fails validation' do
            ActiveModel::Errors.any_instance.stubs(
                    :full_messages).returns([SAMPLE_ERR_MSG])

            get_as @admin,
                    :update_mark,
                    :assignment_id => 1,
                    :submission_id => 1,
                    :id => 1,
                    :mark_id => @mark.id,
                    :mark => 'something'

            assert render_template 'mark_verify_result.rjs'
            assert_response :success
            # Workaround to assert that the error message made its way to the response
            assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
          end

          should 'with save error' do
            @mark.expects(:save).once.returns(false)

            Mark.stubs(:find).once.returns(@mark)
            ActiveModel::Errors.any_instance.stubs(:full_messages).returns([SAMPLE_ERR_MSG])
            get_as @admin,
                   :update_mark,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => 1,
                   :mark_id => 1,
                   :mark => 1
            assert render_template 'shared/_handle_error.js.erb'
            assert_response :success
            # Workaround to assert that the error message made its way to the response
            assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
          end

          should 'without save error' do
            get_as @admin,
                   :update_mark,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => 1,
                   :mark_id => @mark.id,
                   :mark => 1
            assert render_template 'results/marker/_update_mark.rjs'
            assert_response :success
          end

          should 'GET on :view_marks' do
            get_as @admin,
                   :view_marks,
                   :assignment_id => @assignment.id,
                   :submission_id => 1,
                   :id => 1
            assert render_template '404'
            assert_response 404
          end

          should 'GET on :add_extra_mark' do
            get_as @admin,
                   :add_extra_mark,
                   :assignment_id => 1,
                   :submission_id => @submission.id,
                   :id => @submission.get_latest_result.id
            assert_not_nil assigns :result
            assert render_template 'results/marker/add_extra_mark'
            assert_response :success
          end

          context 'POST on :add_extra_mark' do
            should 'with save error' do
              extra_mark = ExtraMark.new
              ExtraMark.expects(:new).once.returns(extra_mark)
              extra_mark.expects(:save).once.returns(false)
              post_as @admin,
                      :add_extra_mark,
                      :assignment_id => 1,
                      :submission_id => @submission.id,
                      :id => @submission.get_latest_result.id,
                      :extra_mark => { :extra_mark => 1 }
              assert_not_nil assigns :result
              assert_not_nil assigns :extra_mark
              assert render_template 'results/marker/add_extra_mark_error'
              assert_response :success
            end

            should 'without save error' do
              @submission.get_latest_result.update_total_mark
              @old_total_mark = @submission.get_latest_result.total_mark
              post_as @admin,
                      :add_extra_mark,
                      :assignment_id => 1,
                      :submission_id => @submission.id,
                      :id => @submission.get_latest_result.id,
                      :extra_mark => { :extra_mark => 1 }
              assert_not_nil assigns :result
              assert_not_nil assigns :extra_mark
              assert render_template 'results/marker/insert_extra_mark'
              assert_response :success

              @submission.get_latest_result.reload
              assert_equal @old_total_mark + 1, @submission.get_latest_result.total_mark
            end
          end
        end

        should 'GET on :remove_extra_mark' do
          @result = Result.make
          (3..4).each do |extra_mark_value|
            @extra_mark = ExtraMark.new
            @extra_mark.unit = ExtraMark::UNITS[:points]
            @extra_mark.result = @result
            @extra_mark.extra_mark = extra_mark_value
            assert @extra_mark.save
          end
          @result.update_total_mark
          @old_total_mark = @result.total_mark
          get_as @admin,
                 :remove_extra_mark,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => @extra_mark.id

          assert_equal true, flash.empty?
          assert_not_nil assigns :result
          assert render_template 'results/marker/remove_extra_mark'
          assert_response :success

          @result.reload
          assert_equal @old_total_mark - @extra_mark.extra_mark, @result.total_mark
        end

        should 'POST on :update_overall_comment' do
          @result = Result.make
          @overall_comment = 'A new overall comment!'
          post_as @admin,
                  :update_overall_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @overall_comment}
          @result.reload
          assert_equal @result.overall_comment, @overall_comment
        end

        should 'POST on :update_overall_remark_comment' do
          @result = Result.make
          @overall_comment = 'A new overall remark comment!'
          post_as @admin,
                  :update_overall_remark_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @overall_comment}

          @result.reload
          assert_equal @result.overall_comment, @overall_comment
        end

      end
    end
  end # An authenticated and authorized admin doing a

  context 'A TA' do

    {:setup_ta_flexible => 'flexible',
     :setup_ta_rubric => 'rubric'}.each do |setup_method, scheme_type|

      context "in an assignment with #{scheme_type} scheme doing a" do
        setup do
          @ta = Ta.make
          @assignment = Assignment.make(:marking_scheme_type => scheme_type)
        end

        should 'GET on :edit' do
          result = Result.make
          get_as @ta,
                 :edit,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => result.id

          assert_equal true, flash.empty?
          assert render_template :edit
          assert_response :success
        end

        context 'GET on :next_grouping' do
          should 'when current grouping has submission' do
            grouping = Grouping.make
            Grouping.any_instance.stubs(:has_submission).returns(true)
            get_as @ta,
                   :next_grouping,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => grouping.id

            assert_response :redirect
          end

          should 'when current grouping has no submission' do
            grouping = Grouping.make
            Grouping.any_instance.stubs(:has_submission).returns(false)
            get_as @ta,
                   :next_grouping,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => grouping.id
            assert_response :redirect
          end
        end

        should 'GET on :set_released_to_students' do
          result = Result.make
          get_as @ta,
                 :set_released_to_students,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => result.id
          assert_response :missing
          assert render_template 404
        end

        should 'GET on :update_marking_state' do
          result = Result.make
          get_as @ta,
                  :update_marking_state,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => result.id,
                  :marking_state => 'complete'
          assert_response :success
          assert_not_nil assigns :result
        end

        context 'GET on :download' do
          setup do
            @file = SubmissionFile.new
          end

          should 'without file error' do
            @file.expects(:filename).once.returns('filename')
            @file.expects(:is_supported_image?).once.returns(false)
            @file.expects(:is_pdf?).once.returns(false)
            @file.expects(:retrieve_file).once.returns('file content')
            SubmissionFile.stubs(:find).returns(@file)

            get_as @ta,
                   :download,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => 1,
                   :select_file_id => 1
            assert_equal true, flash.empty?
            assert_equal 'application/octet-stream', response.header['Content-Type']
            assert_response :success
            assert_equal 'file content', @response.body
          end

          should 'with file error' do
            submission = Submission.make
            result = Result.make
            submission.expects(:get_latest_result).once.returns(result)
            @file.expects(:submission).twice.returns(submission)
            @file.expects(:retrieve_file).once.raises(
                    Exception.new(SAMPLE_ERR_MSG))
            SubmissionFile.stubs(:find).returns(@file)

            get_as @ta,
                   :download,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :id => 1,
                   :select_file_id => 1
            assert_equal flash[:file_download_error], SAMPLE_ERR_MSG
            assert_response :redirect
          end

          should 'with supported image to be displayed inside browser' do
            @file.expects(:filename).once.returns('filename.supported_image')
            @file.expects(:is_supported_image?).once.returns(true)
            @file.expects(:retrieve_file).returns('file content')
            SubmissionFile.stubs(:find).returns(@file)

            get_as @ta,
                    :download,
                    :assignment_id => 1,
                    :submission_id => 1,
                    :id => 1,
                    :select_file_id => 1,
                    :show_in_browser => true
            assert_equal true, flash.empty?
            assert_equal response.header['Content-Type'], 'image'
            assert_response :success
            assert_equal 'file content', @response.body
          end
        end

        context 'GET on :codeviewer' do
          setup do
            @submission_file = SubmissionFile.make
          end

          should 'be able to codeviewer with file reading error' do
            # We simulate a file reading error.
            SubmissionFile.any_instance.expects(:retrieve_file
                      ).once.raises(Exception.new(SAMPLE_ERR_MSG))
            get_as @ta,
                    :codeviewer,
                    :assignment_id => @assignment.id,
                    :submission_id => 1,
                    :submission_file_id => @submission_file.id,
                    :id => 1,
                    :focus_line => 1
            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_not_nil assigns :file
            assert_not_nil assigns :result
            assert_not_nil assigns :annots
            assert_not_nil assigns :all_annots
            assert_nil assigns :file_contents
            assert_nil assigns :code_type
            assert render_template 'shared/_handle_error.js.erb'
            assert_response :success
            # Workaround to assert that the error message made its way to the
            # response
            assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
          end  # -- with file reading error

          should 'without error' do
            # We don't want to access a real file.
            SubmissionFile.any_instance.expects(:retrieve_file).once.returns('file content')
            SubmissionFile.stubs(:find).returns(@submission_file)
            get_as @ta,
                    :codeviewer,
                    :assignment_id => @assignment.id,
                    :submission_id => 1,
                    :submission_file_id => @submission_file.id,
                    :id => 1,
                    :focus_line => 1

            assert_not_nil assigns :assignment
            assert_not_nil assigns :submission_file_id
            assert_not_nil assigns :focus_line
            assert_not_nil assigns :file
            assert_not_nil assigns :result
            assert_not_nil assigns :annots
            assert_not_nil assigns :all_annots
            assert render_template 'results/common/codeviewer'
            assert_response :success
          end  # -- without error
        end

        context 'GET on :update_mark' do
          setup do
            @mark = Mark.make
          end

          should 'fails validation' do
            ActiveModel::Errors.any_instance.stubs(:full_messages).returns([SAMPLE_ERR_MSG])
            get_as @ta,
                    :update_mark,
                    :assignment_id => 1,
                    :submission_id => 1,
                    :id => 1,
                    :mark_id => @mark.id,
                    :mark => 'something'
            assert render_template 'mark_verify_result.rjs'
            assert_response :success
            # Workaround to assert that the error message made its way to the response
            assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
          end

          should 'without save error' do
            get_as @ta,
                   :update_mark,
                   :assignment_id => 1,
                   :submission_id => 1,
                   :mark_id => @mark.id,
                   :mark => 1
            assert render_template 'results/marker/_update_mark.rjs'
            assert_response :success
          end
        end  # -- GET on :update_mark

        should 'GET on :view_marks' do
          get_as @ta,
                 :view_marks,
                 :assignment_id => @assignment.id,
                 :submission_id => 1,
                 :id => 1
          assert render_template '404'
          assert_response 404
        end  # -- GET on :view_marks

        should 'GET on :add_extra_mark' do
          unmarked_result = Result.make
          get_as @ta,
                 :add_extra_mark,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => unmarked_result.id
          assert_not_nil assigns :result
          assert render_template 'results/marker/add_extra_mark'
          assert_response :success
        end

        context 'POST on :add_extra_mark' do
          setup do
            @unmarked_result = Result.make
          end

          should 'with save error' do
            extra_mark = ExtraMark.new
            ExtraMark.expects(:new).once.returns(extra_mark)
            extra_mark.expects(:save).once.returns(false)
            post_as @ta,
                    :add_extra_mark,
                    :assignment_id => 1,
                    :submission_id => 1,
                    :id => @unmarked_result.id,
                    :extra_mark => {:extra_mark => 1}
            assert_not_nil assigns :result
            assert_not_nil assigns :extra_mark
            assert render_template 'results/marker/add_extra_mark_error'
            assert_response :success
          end  # -- with save error

          should 'without save error' do
            @unmarked_result.update_total_mark
            @old_total_mark = @unmarked_result.total_mark
            post_as @ta,
                    :add_extra_mark,
                    :assignment_id => 1,
                    :submission_id => 1,
                    :id => @unmarked_result.id,
                    :extra_mark => {:extra_mark => 1}
            assert_not_nil assigns :result
            assert_not_nil assigns :extra_mark
            assert render_template 'results/marker/insert_extra_mark'
            assert_response :success

            @unmarked_result.reload
            assert_equal @old_total_mark + 1, @unmarked_result.total_mark
          end
        end

        should 'GET on :remove_extra_mark' do
          # create and save extra marks
          @result = Result.make
          (3..4).each do |extra_mark_value|
            @extra_mark = ExtraMark.new
            @extra_mark.unit = ExtraMark::UNITS[:points]
            @extra_mark.result = @result
            @extra_mark.extra_mark = extra_mark_value
            assert @extra_mark.save
          end
          @result.update_total_mark
          @old_total_mark = @result.total_mark
          get_as @ta,
                 :remove_extra_mark,
                 :assignment_id => 1,
                 :submission_id => 1,
                 :id => @extra_mark.id
          assert_equal true, flash.empty?
          assert_not_nil assigns :result
          assert render_template 'results/marker/remove_extra_mark'
          assert_response :success

          @result.reload
          assert_equal @old_total_mark - @extra_mark.extra_mark,
                        @result.total_mark
        end

        should 'POST on :update_overall_comment' do
          @overall_comment = 'A new overall comment!'
          @result = Result.make
          post_as @ta,
                  :update_overall_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @overall_comment}
          @result.reload
          assert_equal @result.overall_comment, @overall_comment
        end

        should 'POST on :update_overall_remark_comment' do
          @result = Result.make
          @overall_comment = 'A new overall remark comment!'
          post_as @ta,
                  :update_overall_remark_comment,
                  :assignment_id => 1,
                  :submission_id => 1,
                  :id => @result.id,
                  :result => {:overall_comment => @overall_comment}
          @result.reload
          assert_equal @result.overall_comment, @overall_comment
        end
      end
    end
  end # An authenticated and authorized TA doing a
end
