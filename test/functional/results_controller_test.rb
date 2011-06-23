require File.dirname(__FILE__) + '/authenticated_controller_test'
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../blueprints/helper'
require 'shoulda'
require 'mocha'
require 'fastercsv'

class ResultsControllerTest < AuthenticatedControllerTest
  fixtures :all

  preload_factory_data :assignments_for_results_controller_test,
    :submission_files_for_result_controller_test,
    :admins_for_result_controller_test

  # Data are defined in test/factory_data/results_controller_test_data.rb
  def setup_student(marking_scheme_type)
    assignment_name = "assignment_" + marking_scheme_type
    @assignment = FactoryData.assignments_for_results_controller_test(assignment_name.to_sym)
    grouping = @assignment.groupings[0]
    @student = grouping.students.first
    @result = grouping.submissions.first.result
  end

  def setup_student_rubric
    setup_student('rubric')
  end

  def setup_student_flexible
    setup_student('flexible')
  end

  def setup_admin(marking_scheme_type)
    @admin = FactoryData.admins_for_result_controller_test(:admin)
    assignment_name = "assignment_" + marking_scheme_type
    @assignment = FactoryData.assignments_for_results_controller_test(assignment_name.to_sym)
    @grouping = @assignment.groupings[0]
    @submission = @assignment.groupings[1].submissions.first
    @result = @assignment.groupings[1].submissions.first.result
    @released_result = @assignment.groupings[0].submissions.first.result
    @mark = @result.marks.first
    @extra_mark = @result.extra_marks.first
  end

  def setup_admin_rubric
    setup_admin('rubric')
  end

  def setup_admin_flexible
    setup_admin('flexible')
  end

  def setup_ta(marking_scheme_type)
    setup_admin(marking_scheme_type)
    @ta = @assignment.ta_memberships.first.user
  end

  def setup_ta_rubric
    setup_ta('rubric')
  end

  def setup_ta_flexible
    setup_ta('flexible')
  end

  SAMPLE_ERR_MSG = "sample error message"

  context "An unauthenticated and unauthorized user doing a" do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    context "GET on :index" do
      setup do
        get :index, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :edit" do
      setup do
        get :edit, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :next_grouping" do
      setup do
        get :next_grouping, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :set_released_to_student" do
      setup do
        get :set_released_to_student, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :update_marking_state" do
      setup do
        get :update_marking_state, :id => 1, :value => 1
      end
      should respond_with :redirect
    end

    context "GET on :update_overall_comment" do
      setup do
        get :update_overall_comment, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :update_overall_remark_comment" do
      setup do
        get :update_overall_remark_comment, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :update_remark_request" do
      setup do
        get :update_remark_request, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :cancel_remark_request" do
      setup do
        get :cancel_remark_request, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :download" do
      setup do
        get :download, :select_file_id => 1
      end
      should respond_with :redirect
    end

    context "GET on :codeviewer" do
      setup do
        get :codeviewer, :id => 1, :submission_file_id => 1, :focus_line => 1
      end
      should respond_with :redirect
    end

    context "GET on :update_mark" do
      setup do
        get :update_mark, :mark_id => 1, :mark => 0
      end
      should respond_with :redirect
    end

    context "GET on :view_marks" do
      setup do
        get :view_marks, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :add_extra_mark" do
      setup do
        get :add_extra_mark, :id => 1, :extra_mark => 1
      end
      should respond_with :redirect
    end

    context "POST on :add_extra_mark" do
      setup do
        post :add_extra_mark, :id => 1, :extra_mark => 1
      end
      should respond_with :redirect
    end

    context "GET on :remove_extra_mark" do
      setup do
        get :remove_extra_mark, :id => 1
      end
      should respond_with :redirect
    end

    context "GET on :expand_criteria" do
      setup do
        get :expand_criteria, :aid => 1
      end
      should respond_with :redirect
    end

    context "GET on :collapse_criteria" do
      setup do
        get :collapse_criteria, :aid => 1
      end
      should respond_with :redirect
    end

    context "GET on :expand_unmarked_criteria" do
      setup do
        get :expand_unmarked_criteria, :aid => 1, :rid => 1
      end
      should respond_with :redirect
    end

  end # unauthenticated and unauthorized user doing

  context "An authenticated and authorized student" do

    {:setup_student_flexible => "flexible", :setup_student_rubric => "rubric"}.each do |setup_method, scheme_type|
      context "in an assignment with #{scheme_type} scheme doing a" do

        setup do
          send setup_method
        end

        context "GET on :index" do
          setup do
            get_as @student, :index, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :edit" do
          setup do
            get_as @student, :edit, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :next_grouping" do
          setup do
            get_as @student, :next_grouping, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :set_released_to_student" do
          setup do
            get_as @student, :set_released_to_student, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :update_marking_state" do
          setup do
            get_as @student, :update_marking_state, :id => 1, :value => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :update_overall_comment" do
          setup do
            @new_comment = 'a changed overall comment!'
            get_as @student, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @new_comment}
          end
          should respond_with :missing
          should render_template 404
          should "not have changed the overall comment" do
            @result.reload
            assert_not_equal @result.overall_comment, @new_comment
          end
        end

        context "POST on :update_overall_comment" do
          setup do
            @new_comment = 'a changed overall comment!'
            post_as @student, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @new_comment}
          end
          should respond_with :missing
          should render_template 404
          should "not have changed the overall comment" do
            @result.reload
            assert_not_equal @result.overall_comment, @new_comment
          end
        end

        context "GET on :update_overall_remark_comment" do
          setup do
            @new_comment = 'a changed overall remark comment!'
            get_as @student, :update_overall_remark_comment, :id => @result.id, :result => {:overall_comment => @new_comment}
          end
          should respond_with :missing
          should render_template 404
          should "not have changed the overall remark comment" do
            @result.reload
            assert_not_equal @result.overall_comment, @new_comment
          end
        end

        context "POST on :update_overall_remark_comment" do
          setup do
            @new_comment = 'a changed overall remark comment!'
            post_as @student, :update_overall_remark_comment, :id => @result.id, :result => {:overall_comment => @new_comment}
          end
          should respond_with :missing
          should render_template 404
          should "not have changed the overall remark comment" do
            @result.reload
            assert_not_equal @result.overall_comment, @new_comment
          end
        end

        context "GET on :download" do
          setup do
            @file = SubmissionFile.new
          end

          context "without file error" do

            context "with permissions to download the file" do
              setup do
                @file.expects(:filename).once.returns('filename')
                @file.expects(:is_supported_image?).once.returns(false)
                @file.expects(:is_pdf?).once.returns(false)
                @file.expects(:retrieve_file).returns('file content')
                SubmissionFile.expects(:find).with('1').returns(@file)
                ResultsController.any_instance.stubs(:authorized_to_download?).once.returns(true)
                get_as @student, :download, :select_file_id => 1
              end
              should_not set_the_flash
              should respond_with_content_type "application/octet-stream"
              should respond_with :success
              should "respond with appropriate content" do
                assert_equal 'file content', @response.body
              end
            end

            context "without permissions to download the file" do
              setup do
                ResultsController.any_instance.stubs(:authorized_to_download?).once.returns(false)
                get_as @student, :download, :select_file_id => 1
              end
              should_not set_the_flash
              should respond_with :missing
              should render_template 404
            end
          end

          context "with file error" do
            setup do
              submission = Submission.new
              submission.expects(:result).once.returns(@result)
              @file.expects(:submission).once.returns(submission)
              SubmissionFile.expects(:find).with('1').returns(@file)
              ResultsController.any_instance.expects(:authorized_to_download?).once.returns(true)
              @file.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
              get_as @student, :download, :select_file_id => 1
            end
            should set_the_flash.to(SAMPLE_ERR_MSG)
            should respond_with :redirect
          end

        context "with supported image to be displayed inside browser" do
            setup do
              @file.expects(:filename).once.returns('filename.supported_image')
              @file.expects(:is_supported_image?).once.returns(true)
              @file.expects(:retrieve_file).returns('file content')
              SubmissionFile.expects(:find).with('1').returns(@file)
              ResultsController.any_instance.expects(:authorized_to_download?).once.returns(true)
              get_as @student, :download, :select_file_id => 1, :show_in_browser => true
            end
            should_not set_the_flash
            should respond_with_content_type "image"
            should respond_with :success
            should "respond with appropriate content" do
              assert_equal 'file content', @response.body
            end
          end

          context "with annotations included" do
              setup do
                @file.expects(:filename).once.returns('filename')
                @file.expects(:is_supported_image?).once.returns(false)
                @file.expects(:is_pdf?).once.returns(false)
                @file.expects(:retrieve_file).returns('file content')
                SubmissionFile.expects(:find).with('1').returns(@file)
                ResultsController.any_instance.stubs(:authorized_to_download?).once.returns(true)
                get_as @student, :download, :select_file_id => 1, :include_annotations => true
              end
              should_not set_the_flash
              should respond_with_content_type "application/octet-stream"
              should respond_with :success
              should "respond with appropriate content" do
                assert_equal 'file content', @response.body
              end
            end
        end

        context "GET on :codeviewer" do
          setup do
            @submission_file = @result.submission.submission_files.first
          end

          context "and the student has no access to that file" do
            setup do
              @no_access_submission_file = FactoryData.submission_files_for_result_controller_test(:no_access_submission_file)
              get_as @student, :codeviewer, :id => @assignment.id, :submission_file_id => @no_access_submission_file.id, :focus_line => 1
            end
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should_not assign_to :file_contents
            should_not assign_to :annots
            should_not assign_to :all_annots
            should render_template 'shared/_handle_error.rjs'
            should respond_with :success
            should "set an appropriate error message" do
              # Workaround to assert that the error message made its way to the response
              r = Regexp.new(I18n.t('submission_file.error.no_access', :submission_file_id => @no_access_submission_file.id))
              assert_match r, @response.body
            end
          end

          context "with file reading error" do
            setup do
              # We simulate a file reading error.
              SubmissionFile.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
              get_as @student, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
            end
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should assign_to :file
            should assign_to :result
            should assign_to :annots
            should assign_to :all_annots
            should_not assign_to :file_contents
            should_not assign_to :code_type
            should render_template 'shared/_handle_error.rjs'
            should respond_with :success
            should "pass along the exception's message" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end

          context "without error" do
            setup do
              # We don't want to access a real file.
              SubmissionFile.any_instance.expects(:retrieve_file).once.returns('file content')
              get_as @student, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
            end
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should assign_to :file
            should assign_to :result
            should assign_to :annots
            should assign_to :all_annots
            should assign_to :file_contents
            should assign_to :code_type
            should render_template 'results/common/codeviewer'
            should respond_with :success
          end

        end

        context "GET on :update_mark" do
          setup do
            get_as @student, :update_mark, :mark_id => 1, :mark => 0
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :view_marks" do

          context "and his grouping has no submission" do
            setup do
              Grouping.any_instance.expects(:has_submission?).once.returns(false)
              get_as @student, :view_marks, :id => @assignment.id
            end
            should assign_to :assignment
            should assign_to :grouping
            should render_template 'results/student/no_submission'
            should respond_with :success
          end

          context "and his submission has no result" do
            setup do
              Submission.any_instance.expects(:has_result?).once.returns(false)
              get_as @student, :view_marks, :id => @assignment.id
            end
            should assign_to :assignment
            should assign_to :grouping
            should assign_to :submission
            should render_template 'results/student/no_result'
            should respond_with :success
          end

          context "and the result has not been released" do
            setup do
              Result.any_instance.expects(:released_to_students).once.returns(false)
              get_as @student, :view_marks, :id => @assignment.id
            end
            should assign_to :assignment
            should assign_to :grouping
            should assign_to :submission
            should assign_to :result
            should render_template 'results/student/no_result'
            should respond_with :success
          end

          context "and the result is available" do
            setup do
              get_as @student, :view_marks, :id => @assignment.id
            end
            should assign_to :assignment
            should assign_to :grouping
            should assign_to :submission
            should assign_to :result
            should assign_to :mark_criteria
            should assign_to :annotation_categories
            should assign_to :group
            should assign_to :files
            should assign_to :first_file
            should assign_to :extra_marks_points
            should assign_to:extra_marks_percentage
            should assign_to :marks_map
            should respond_with :success
            should render_template :view_marks
          end
        end

        context "GET on :add_extra_mark" do
          setup do
            get_as @student, :add_extra_mark, :id => 1, :extra_mark => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :remove_extra_mark" do
          setup do
            get_as @student, :remove_extra_mark, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :expand_criteria" do
          setup do
            get_as @student, :expand_criteria, :aid => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :collapse_criteria" do
          setup do
            get_as @student, :collapse_criteria, :aid => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :expand_unmarked_criteria" do
          setup do
            get_as @student, :expand_unmarked_criteria, :aid => 1, :rid => 1
          end
          should respond_with :missing
          should render_template 404
        end
      end
    end
  end # An authenticated and authorized student doing a

  context "An authenticated and authorized admin doing a" do

    {:setup_admin_flexible => "flexible", :setup_admin_rubric => "rubric"}.each do |setup_method, scheme_type|
      context "in an assignment with #{scheme_type} scheme doing a" do
        setup do
          send setup_method
        end

        context "GET on :edit" do
          context "with 2 partial and 1 released/completed results" do
            setup do
              # the results will be sorted by group name alphabatically,
              # but I created them in reverse order.
              # see test/factory_data/results_controller_test_data.rb
              @result_first = @assignment.groupings[2].submissions[0].result
              @result_second = @assignment.groupings[1].submissions[0].result
              @result_third = @assignment.groupings[0].submissions[0].result
            end
            context "when editing first result" do
              setup do
                get_as @admin, :edit, :id => @result_first.id
              end
              should "have set next_submission and prev_submission correctly" do
                assert assigns(:next_grouping)
                next_grouping = assigns(:next_grouping)
                assert next_grouping.has_submission?
                next_result = next_grouping.current_submission_used.result
                assert_not_nil next_result
                assert_equal next_result, @result_second
                assert !next_result.released_to_students
                assert_nil assigns(:previous_grouping)
              end
              should_not set_the_flash
              should render_template :edit
              should respond_with :success
            end
            context "when editing second result" do
              setup do
                get_as @admin, :edit, :id => @result_second.id
              end
              should "have set next_submission and prev_submission correctly" do
                assert assigns(:next_grouping)
                assert assigns(:previous_grouping)
                next_grouping = assigns(:next_grouping)
                previous_grouping = assigns(:previous_grouping)
                assert next_grouping.has_submission?
                assert previous_grouping.has_submission?
                next_result = next_grouping.current_submission_used.result
                previous_result = previous_grouping.current_submission_used.result
                assert_not_nil next_result
                assert_not_nil previous_result
                assert_equal next_result, @result_third
                assert_equal previous_result, @result_first
                assert next_result.released_to_students
                assert !previous_result.released_to_students
              end
              should_not set_the_flash
              should render_template :edit
              should respond_with :success
            end
            context "when editing third result" do
              setup do
                get_as @admin, :edit, :id => @result_third.id
              end
              should "have set next_submission and prev_submission correctly" do
                assert_nil assigns(:next_grouping)
                assert assigns(:previous_grouping)
                previous_grouping = assigns(:previous_grouping)
                assert previous_grouping.has_submission?
                previous_result = previous_grouping.current_submission_used.result
                assert_not_nil previous_result
                assert_equal previous_result, @result_second
                assert !previous_result.released_to_students
              end
              should_not set_the_flash
              should render_template :edit
              should respond_with :success
            end

          end
        end

        context "GET on :next_grouping" do

          context "when current grouping has submission" do
            setup do
              Grouping.any_instance.stubs(:has_submission).returns(true)
              get_as @admin, :next_grouping, :id => @grouping.id
            end
            should respond_with :redirect
          end

          context "when current grouping has no submission" do
            setup do
              Grouping.any_instance.stubs(:has_submission).returns(false)
              get_as @admin, :next_grouping, :id => @grouping.id
            end
            should respond_with :redirect
          end

        end

        context "GET on :set_released_to_students" do
          setup do
            get_as @admin, :set_released_to_students, :id => @result.id, :value => 'true'
          end
          should respond_with :success
          should assign_to :result
        end

        context "GET on :update_marking_state" do
          setup do
            # refresh the grade distribution - there's already a completed mark so far
            # for each rubric type, in the following grade range:
            # flexible: 6-10%
            # rubric: 21-25%
            @assignment.assignment_stat.refresh_grade_distribution
            @grade_distribution = @assignment.assignment_stat.grade_distribution_percentage

            # convert @grade_distribution csv to an array
            @grade_distribution = @grade_distribution.parse_csv.map{ |x| x.to_i }

            # after the call to get_as, a second result for each marking scheme type
            # will be marked as complete, a result which will be in the same grade range
            # therefore we must increment the number of groupings at the given range for
            # each marking scheme type
            if @assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:flexible]
              # increment the 6-10% range
              @grade_distribution[1] += 1
            end
            if @assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:rubric]
              # increment the 21-25% range
              @grade_distribution[4] += 1
            end

            get_as @admin, :update_marking_state, {:id => @result.id, :value => 'complete'}
          end
          should "refresh the cached grade distribution data when the marking state is set to complete" do
            @assignment.reload
            actual_distribution = @assignment.assignment_stat.grade_distribution_percentage.parse_csv.map{ |x| x.to_i }
            assert_equal actual_distribution, @grade_distribution
          end
          should respond_with :success
          should assign_to :result
        end

        context "GET on :download" do
          setup do
            @file = SubmissionFile.new
          end

          context "without file error" do
            setup do
              @file.expects(:filename).once.returns('filename')
              @file.expects(:retrieve_file).returns('file content')
              @file.expects(:is_supported_image?).once.returns(false)
              @file.expects(:is_pdf?).once.returns(false)
              SubmissionFile.expects(:find).with('1').returns(@file)
              get_as @admin, :download, :select_file_id => 1
            end
            should_not set_the_flash
            should respond_with_content_type "application/octet-stream"
            should respond_with :success
            should "respond with appropriate content" do
              assert_equal 'file content', @response.body
            end
          end

          context "with file error" do
            setup do
              submission = Submission.new
              submission.expects(:result).once.returns(@result)
              @file.expects(:submission).once.returns(submission)
              SubmissionFile.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
              SubmissionFile.expects(:find).with('1').returns(@file)
              get_as @admin, :download, :select_file_id => 1
            end
            should set_the_flash.to(SAMPLE_ERR_MSG)
            should respond_with :redirect
          end

          context "with supported image to be displayed inside browser" do
              setup do
                @file.expects(:filename).once.returns('filename.supported_image')
                @file.expects(:retrieve_file).returns('file content')
                @file.expects(:is_supported_image?).once.returns(true)
                SubmissionFile.expects(:find).with('1').returns(@file)
                get_as @admin, :download, :select_file_id => 1, :show_in_browser => true
              end
              should_not set_the_flash
              should respond_with_content_type "image"
              should respond_with :success
              should "respond with appropriate content" do
                assert_equal 'file content', @response.body
              end
            end
          end

        context "GET on :codeviewer" do
          setup do
            @file = SubmissionFile.new
            annotation = Annotation.new
            SubmissionFile.expects(:find).once.with('1').returns(@file)
            @file.expects(:submission).twice.returns(@submission)
            @file.expects(:annotations).once.returns(annotation)
          end

          context "without file error" do
            setup do
              @file.expects(:get_file_type).once.returns('txt')
              SubmissionFile.any_instance.expects(:retrieve_file).once.returns('file content')
              get_as @admin, :codeviewer, :id => @assignment.id, :submission_file_id => 1, :focus_line => 1
            end
            should_not set_the_flash
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should assign_to :file
            should assign_to :result
            should assign_to :annots
            should assign_to :all_annots
            should assign_to :file_contents
            should assign_to :code_type
            should render_template 'results/common/codeviewer'
            should respond_with :success
          end

          context "with file error" do
            setup do
              SubmissionFile.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
              get_as @admin, :codeviewer, :id => @assignment.id, :submission_file_id => 1, :focus_line => 1
            end
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should assign_to :file
            should assign_to :result
            should assign_to :annots
            should assign_to :all_annots
            should_not assign_to :file_contents
            should_not assign_to :code_type
            should render_template 'shared/_handle_error.rjs'
            should respond_with :success
            should "pass along the exception's message" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end
        end

        context "GET on :update_mark" do
          setup do
          end

          context "fails validation" do
             setup do
              Mark.expects(:find).with('1').returns(@mark)
              @mark.expects(:valid?).once.returns(false)
              ActiveRecord::Errors.any_instance.stubs(:full_messages).returns([SAMPLE_ERR_MSG])
              get_as @admin, :update_mark, :mark_id => 1, :mark => 1
            end
            should render_template 'mark_verify_result.rjs'
            should respond_with :success
            should "pass along the \"error hash\"" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end

          context "with save error" do
            setup do
              Mark.expects(:find).with('1').returns(@mark)
              @mark.expects(:save).once.returns(false)
              ActiveRecord::Errors.any_instance.stubs(:full_messages).returns([SAMPLE_ERR_MSG])
              get_as @admin, :update_mark, :mark_id => 1, :mark => 1
            end
            should render_template 'shared/_handle_error.rjs'
            should respond_with :success
            should "pass along the \"error hash\"" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end

          context "without save error" do
            setup do
              get_as @admin, :update_mark, :mark_id => @mark.id, :mark => 1
            end
            should render_template 'results/marker/_update_mark.rjs'
            should respond_with :success
          end

        end

        context "GET on :view_marks" do
          setup do
            get_as @admin, :view_marks, :id => @assignment.id
          end
          should render_template '404'
          should respond_with 404
        end

        context "GET on :add_extra_mark" do
          setup do
            get_as @admin, :add_extra_mark, :id => @result.id
          end
          should assign_to :result
          should render_template 'results/marker/add_extra_mark'
          should respond_with :success
        end

        context "POST on :add_extra_mark" do

          context "with save error" do
            setup do
              extra_mark = ExtraMark.new
              ExtraMark.expects(:new).once.returns(extra_mark)
              extra_mark.expects(:save).once.returns(false)
              post_as @admin, :add_extra_mark, :id => @result.id, :extra_mark => { :extra_mark => 1 }
            end
            should assign_to :result
            should assign_to :extra_mark
            should render_template 'results/marker/add_extra_mark_error'
            should respond_with :success
          end

          context "without save error" do
            setup do
              @result.update_total_mark
              @old_total_mark = @result.total_mark
              post_as @admin, :add_extra_mark, :id => @result.id, :extra_mark => { :extra_mark => 1 }
            end
            should assign_to :result
            should assign_to :extra_mark
            should render_template 'results/marker/insert_extra_mark'
            should respond_with :success

            should "have added the extra mark and updated total mark accordingly" do
              @result.reload
              assert_equal @old_total_mark + 1, @result.total_mark
            end
          end

        end

        context "GET on :remove_extra_mark" do
          setup do
            # clear any existing extra marks
            @result.extra_marks.map{ |mark| mark.destroy }
            # create and save extra marks
            (3..4).each do |extra_mark_value|
              @extra_mark = ExtraMark.new
              @extra_mark.unit = ExtraMark::UNITS[:points]
              @extra_mark.result = @result
              @extra_mark.extra_mark = extra_mark_value
              assert @extra_mark.save
            end
            @result.update_total_mark
            @old_total_mark = @result.total_mark
            get_as @admin, :remove_extra_mark, :id => @extra_mark.id
          end
          should_not set_the_flash
          should assign_to :result
          should render_template 'results/marker/remove_extra_mark'
          should respond_with :success

          should "have removed the extra mark in question and updated the total mark accordingly" do
            @result.reload
            assert_equal @old_total_mark - @extra_mark.extra_mark, @result.total_mark
          end
        end

        context "GET on :expand_criteria" do
          setup do
            get_as @admin, :expand_criteria, :aid => @assignment.id
          end
          should assign_to :assignment
          should assign_to :mark_criteria
          should render_template 'results/marker/_expand_criteria.rjs'
          should respond_with :success
        end

        context "GET on :collapse_criteria" do
          setup do
            get_as @admin, :collapse_criteria, :aid => @assignment.id
          end
          should assign_to :assignment
          should assign_to :mark_criteria
          should render_template 'results/marker/_collapse_criteria.rjs'
          should respond_with :success
        end

        context "GET on :expand_unmarked_criteria" do
          setup do
            get_as @admin, :expand_unmarked_criteria, :aid => @assignment.id, :rid => @result.id
          end
          should assign_to :assignment
          should assign_to :result
          should assign_to :nil_marks
          should render_template 'results/marker/_expand_unmarked_criteria'
          should respond_with :success
        end

        context "POST on :update_overall_comment" do
          setup do
            @overall_comment = "A new overall comment!"
            post_as @admin, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @overall_comment}
          end
          should "update the overall comment" do
            @result.reload
            assert_equal @result.overall_comment, @overall_comment
          end
        end

        context "POST on :update_overall_remark_comment" do
          setup do
            @overall_comment = "A new overall remark comment!"
            post_as @admin, :update_overall_remark_comment, :id => @result.id, :result => {:overall_comment => @overall_comment}
          end
          should "update the overall remark comment" do
            @result.reload
            assert_equal @result.overall_comment, @overall_comment
          end
        end
      end
    end
  end # An authenticated and authorized admin doing a

  context "An authenticated and authorized TA doing a" do
    fixtures :users

    {:setup_ta_flexible => "flexible", :setup_ta_rubric => "rubric"}.each do |setup_method, scheme_type|
      context "in an assignment with #{scheme_type} scheme doing a" do

        setup do
          send setup_method
        end

        context "GET on :index" do
          setup do
            get_as @ta, :index, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :edit" do
          setup do
            get_as @ta, :edit, :id => @result.id
          end
          should_not set_the_flash
          should render_template :edit
          should respond_with :success
        end

        context "GET on :next_grouping" do

          context "when current grouping has submission" do
            setup do
              Grouping.any_instance.stubs(:has_submission).returns(true)
              get_as @ta, :next_grouping, :id => @grouping.id
            end
            should respond_with :redirect
          end

          context "when current grouping has no submission" do
            setup do
              Grouping.any_instance.stubs(:has_submission).returns(false)
              get_as @ta, :next_grouping, :id => @grouping.id
            end
            should respond_with :redirect
          end

        end

        context "GET on :set_released_to_student" do
          setup do
            get_as @ta, :set_released_to_student, :id => 1
          end
          should respond_with :missing
          should render_template 404
        end

        context "GET on :update_marking_state" do
          setup do
            get_as @ta, :update_marking_state, :id => @result.id, :marking_state => 'complete'
          end
          should respond_with :success
          should assign_to :result
        end

        context "GET on :download" do
          setup do
            @file = SubmissionFile.new
          end

          context "without file error" do
            setup do
              @file.expects(:filename).once.returns('filename')
              @file.expects(:is_supported_image?).once.returns(false)
              @file.expects(:is_pdf?).once.returns(false)
              @file.expects(:retrieve_file).once.returns('file content')
              SubmissionFile.expects(:find).with('1').returns(@file)
              get_as @ta, :download, :select_file_id => 1
            end
            should_not set_the_flash
            should respond_with_content_type "application/octet-stream"
            should respond_with :success
            should "respond with appropriate content" do
              assert_equal 'file content', @response.body
            end
          end

          context "with file error" do
            setup do
              submission = Submission.new
              submission.expects(:result).once.returns(@result)
              @file.expects(:submission).once.returns(submission)
              SubmissionFile.expects(:find).with('1').returns(@file)
              @file.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
              get_as @ta, :download, :select_file_id => 1
            end
            should set_the_flash.to(SAMPLE_ERR_MSG)
            should respond_with :redirect
          end

          context "with supported image to be displayed inside browser" do
              setup do
                @file.expects(:filename).once.returns('filename.supported_image')
                @file.expects(:is_supported_image?).once.returns(true)
                SubmissionFile.expects(:find).with('1').returns(@file)
                @file.expects(:retrieve_file).returns('file content')
                get_as @ta, :download, :select_file_id => 1, :show_in_browser => true
              end
              should_not set_the_flash
              should respond_with_content_type "image"
              should respond_with :success
              should "respond with appropriate content" do
                assert_equal 'file content', @response.body
              end
            end
          end

        context "GET on :codeviewer" do
          setup do
            @submission_file = FactoryData.submission_files_for_result_controller_test(:no_access_submission_file) # submission_files(:student1_ass_5_sub_1)
          end

          context "with file reading error" do
            setup do
              # We simulate a file reading error.
              SubmissionFile.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
              get_as @ta, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
            end
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should assign_to :file
            should assign_to :result
            should assign_to :annots
            should assign_to :all_annots
            should_not assign_to :file_contents
            should_not assign_to :code_type
            should render_template 'shared/_handle_error.rjs'
            should respond_with :success
            should "pass along the exception's message" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end

          context "without error" do
            setup do
              # We don't want to access a real file.
              SubmissionFile.any_instance.expects(:retrieve_file).once.returns('file content')
              get_as @ta, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
            end
            should assign_to :assignment
            should assign_to :submission_file_id
            should assign_to :focus_line
            should assign_to :file
            should assign_to :result
            should assign_to :annots
            should assign_to :all_annots
            should assign_to :file_contents
            should assign_to :code_type
            should render_template 'results/common/codeviewer'
            should respond_with :success
          end

        end

        context "GET on :update_mark" do

          context "fails validation" do
             setup do
              Mark.expects(:find).with('1').returns(@mark)
              @mark.expects(:valid?).once.returns(false)
              ActiveRecord::Errors.any_instance.stubs(:full_messages).returns([SAMPLE_ERR_MSG])
              get_as @ta, :update_mark, :mark_id => 1, :mark => 1
            end
            should render_template 'mark_verify_result.rjs'
            should respond_with :success
            should "pass along the \"error hash\"" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end

          context "with save error" do
            setup do
              Mark.expects(:find).with('1').returns(@mark)
              @mark.expects(:save).once.returns(false)
              ActiveRecord::Errors.any_instance.stubs(:full_messages).returns([SAMPLE_ERR_MSG])
              get_as @ta, :update_mark, :mark_id => 1, :mark => 1
            end
            should render_template 'shared/_handle_error.rjs'
            should respond_with :success
            should "pass along the \"error hash\"" do
              # Workaround to assert that the error message made its way to the response
              assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
            end
          end

          context "without save error" do
            setup do
              get_as @ta, :update_mark, :mark_id => @mark.id, :mark => 1
            end
            should render_template 'results/marker/_update_mark.rjs'
            should respond_with :success
          end

        end

        context "GET on :view_marks" do
          setup do
            get_as @ta, :view_marks, :id => @assignment.id
          end
          should render_template '404'
          should respond_with 404
        end

        context "GET on :add_extra_mark" do
          setup do
            unmarked_result = @result
            get_as @ta, :add_extra_mark, :id => unmarked_result.id
          end
          should assign_to :result
          should render_template 'results/marker/add_extra_mark'
          should respond_with :success
        end

        context "POST on :add_extra_mark" do
          setup do
            @unmarked_result = @result
          end

          context "with save error" do
            setup do
              extra_mark = ExtraMark.new
              ExtraMark.expects(:new).once.returns(extra_mark)
              extra_mark.expects(:save).once.returns(false)
              post_as @ta, :add_extra_mark, :id => @unmarked_result.id, :extra_mark => { :extra_mark => 1 }
            end
            should assign_to :result
            should assign_to :extra_mark
            should render_template 'results/marker/add_extra_mark_error'
            should respond_with :success
          end

          context "without save error" do
            setup do
              @unmarked_result.update_total_mark
              @old_total_mark = @unmarked_result.total_mark
              post_as @ta, :add_extra_mark, :id => @unmarked_result.id, :extra_mark => { :extra_mark => 1 }
            end
            should assign_to :result
            should assign_to :extra_mark
            should render_template 'results/marker/insert_extra_mark'
            should respond_with :success

            should "have added the extra mark and updated total mark accordingly" do
              @unmarked_result.reload
              assert_equal @old_total_mark + 1, @unmarked_result.total_mark
            end
          end

        end

        context "GET on :remove_extra_mark" do
          setup do
            # clear any existing extra marks
            @result.extra_marks.map{ |mark| mark.destroy }
            # create and save extra marks
            (3..4).each do |extra_mark_value|
              @extra_mark = ExtraMark.new
              @extra_mark.unit = ExtraMark::UNITS[:points]
              @extra_mark.result = @result
              @extra_mark.extra_mark = extra_mark_value
              assert @extra_mark.save
            end
            @result.update_total_mark
            @old_total_mark = @result.total_mark
            get_as @ta, :remove_extra_mark, :id => @extra_mark.id
          end
          should_not set_the_flash
          should assign_to :result
          should render_template 'results/marker/remove_extra_mark'
          should respond_with :success

          should "have removed the extra mark in question and updated the total mark accordingly" do
            @result.reload
            assert_equal @old_total_mark - @extra_mark.extra_mark, @result.total_mark
          end
        end

        context "GET on :expand_criteria" do
          setup do
            get_as @ta, :expand_criteria, :aid => @assignment.id
          end
          should assign_to :assignment
          should assign_to :mark_criteria
          should render_template 'results/marker/_expand_criteria.rjs'
          should respond_with :success
        end

        context "GET on :collapse_criteria" do
          setup do
            get_as @ta, :collapse_criteria, :aid => @assignment.id
          end
          should assign_to :assignment
          should assign_to :mark_criteria
          should render_template 'results/marker/_collapse_criteria.rjs'
          should respond_with :success
        end

        context "GET on :expand_unmarked_criteria" do
          setup do
            get_as @ta, :expand_unmarked_criteria, :aid => @assignment.id, :rid => @result.id
          end
          should assign_to :assignment
          should assign_to :result
          should assign_to :nil_marks
          should render_template 'results/marker/_expand_unmarked_criteria'
          should respond_with :success
        end

        context "POST on :update_overall_comment" do
          setup do
            @overall_comment = "A new overall comment!"
            post_as @ta, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @overall_comment}
          end
          should "update the overall comment" do
            @result.reload
            assert_equal @result.overall_comment, @overall_comment
          end
        end

        context "POST on :update_overall_remark_comment" do
          setup do
            @overall_comment = "A new overall remark comment!"
            post_as @ta, :update_overall_remark_comment, :id => @result.id, :result => {:overall_comment => @overall_comment}
          end
          should "update the overall remark comment" do
            @result.reload
            assert_equal @result.overall_comment, @overall_comment
          end
        end
      end
    end
  end # An authenticated and authorized TA doing a

end
