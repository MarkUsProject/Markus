require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'mocha'

class ResultsControllerTest < AuthenticatedControllerTest

  fixtures :all

  SAMPLE_ERR_MSG = "sample error message"
  
  context "An unauthenticated and unauthorized user doing a" do
    
    # Since we are not authenticated and authorized, we should be redirected
    # to the login page
    
    context "GET on :index" do
      setup do
        get :index, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :edit" do
      setup do
        get :edit, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :next_grouping" do
      setup do
        get :next_grouping, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :set_released_to_student" do
      setup do
        get :set_released_to_student, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :update_marking_state" do
      setup do
        get :update_marking_state, :id => 1, :value => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :update_overall_comment" do
      setup do
        get :update_overall_comment, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :download" do
      setup do
        get :download, :select_file_id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :codeviewer" do
      setup do
        get :codeviewer, :id => 1, :submission_file_id => 1, :focus_line => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :update_mark" do
      setup do
        get :update_mark, :mark_id => 1, :mark => 0
      end
      should_respond_with :redirect
    end
    
    context "GET on :view_marks" do
      setup do
        get :view_marks, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :add_extra_mark" do
      setup do
        get :add_extra_mark, :id => 1, :extra_mark => 1
      end
      should_respond_with :redirect
    end
    
    context "POST on :add_extra_mark" do
      setup do
        post :add_extra_mark, :id => 1, :extra_mark => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :remove_extra_mark" do
      setup do
        get :remove_extra_mark, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :expand_criteria" do
      setup do
        get :expand_criteria, :aid => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :collapse_criteria" do
      setup do
        get :collapse_criteria, :aid => 1
      end
      should_respond_with :redirect
    end
    
    context "GET on :expand_unmarked_criteria" do
      setup do
        get :expand_unmarked_criteria, :aid => 1, :rid => 1
      end
      should_respond_with :redirect
    end
    
  end # unauthenticated and unauthorized user doing
  
  context "An authenticated and authorized student doing a" do
    fixtures :users, :results, :assignments, :marks, :rubric_criteria
    
    setup do
      @student = users(:student1)
      @result = results(:result_5)
      @assignment = assignments(:assignment_5)
    end
    
    context "GET on :index" do
      setup do
        get_as @student, :index, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :edit" do
      setup do
        get_as @student, :edit, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :next_grouping" do
      setup do
        get_as @student, :next_grouping, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :set_released_to_student" do
      setup do
        get_as @student, :set_released_to_student, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :update_marking_state" do
      setup do
        get_as @student, :update_marking_state, :id => 1, :value => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :update_overall_comment" do
      setup do
        @new_comment = 'a changed overall comment!'
        get_as @student, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @new_comment}
      end
      should_respond_with :missing
      should_render_template 404
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
      should_respond_with :missing
      should_render_template 404
      should "not have changed the overall comment" do
        @result.reload
        assert_not_equal @result.overall_comment, @new_comment
      end
    end
    
    context "GET on :download" do
      setup do
        get_as @student, :download, :select_file_id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :codeviewer" do
      setup do
       @submission_file = submission_files(:student1_ass_5_sub_1)
      end
     
      context "and the student has no access to that file" do
        setup do
          @no_access_submission_file = submission_files(:grouping_2_ass_1_sub_2)
          get_as @student, :codeviewer, :id => @assignment.id, :submission_file_id => @no_access_submission_file.id, :focus_line => 1
        end
        should_assign_to :assignment, :submission_file_id, :focus_line
        should_not_assign_to :file_contents, :annots, :all_annots
        should_render_template 'shared/_handle_error.rjs'
        should_respond_with :success
        should "set an appropriate error message" do
          # Workaround to assert that the error message made its way to the response
          r = Regexp.new(I18n.t('submission_file.error.no_access', :submission_file_id => @no_access_submission_file.id))
          assert_match r, @response.body
        end
      end
      
      context "with file reading error" do
        setup do
          # We simulate a file reading error.
          ResultsController.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
          get_as @student, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
        end
        should_assign_to :assignment, :submission_file_id, :focus_line, :file, :result,
                         :annots, :all_annots
        should_not_assign_to :file_contents, :code_type
        should_render_template 'shared/_handle_error.rjs'
        should_respond_with :success
        should "pass along the exception's message" do
          # Workaround to assert that the error message made its way to the response
          assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
        end
      end
      
      context "without error" do
        setup do
          # We don't want to access a real file. 
          ResultsController.any_instance.expects(:retrieve_file).once.returns('file content')
          get_as @student, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
        end
        should_assign_to :assignment, :submission_file_id, :focus_line, :file, :result,
                         :annots, :all_annots, :file_contents, :code_type
        should_render_template 'results/common/codeviewer'
        should_respond_with :success
      end
      
    end
    
    context "GET on :update_mark" do
      setup do
        get_as @student, :update_mark, :mark_id => 1, :mark => 0
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :view_marks" do
      
      context "and his grouping has no submission" do
        setup do
          Grouping.any_instance.expects(:has_submission?).once.returns(false)
          get_as @student, :view_marks, :id => @assignment.id
        end
        should_assign_to :assignment, :grouping
        should_render_template 'results/student/no_submission'
        should_respond_with :success
      end
    
      context "and his submission has no result" do
        setup do
          Submission.any_instance.expects(:has_result?).once.returns(false)
          get_as @student, :view_marks, :id => @assignment.id
        end
        should_assign_to :assignment, :grouping, :submission
        should_render_template 'results/student/no_result'
        should_respond_with :success
      end
    
      context "and the result has not been released" do
        setup do
          Result.any_instance.expects(:released_to_students).once.returns(false)
          get_as @student, :view_marks, :id => @assignment.id
        end
        should_assign_to :assignment, :grouping, :submission, :result
        should_render_template 'results/student/no_result'
        should_respond_with :success
      end
    
      context "and the result is available" do
        setup do
          get_as @student, :view_marks, :id => @assignment.id
        end
        should_assign_to :assignment, :grouping, :submission,
                         :result, :rubric_criteria, :annotation_categories,
                         :group, :files, :first_file, :extra_marks_points,
                         :extra_marks_percentage, :marks_map
        should_respond_with :success
        should_render_template :view_marks
      end
      
    end
    
    context "GET on :add_extra_mark" do
      setup do
        get_as @student, :add_extra_mark, :id => 1, :extra_mark => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :remove_extra_mark" do
      setup do
        get_as @student, :remove_extra_mark, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :expand_criteria" do
      setup do
        get_as @student, :expand_criteria, :aid => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :collapse_criteria" do
      setup do
        get_as @student, :collapse_criteria, :aid => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :expand_unmarked_criteria" do
      setup do
        get_as @student, :expand_unmarked_criteria, :aid => 1, :rid => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
  end # An authenticated and authorized student doing a
  
  context "An authenticated and authorized admin doing a" do
    fixtures :users, :submissions, :submission_files, :groupings, :results, :annotations, :marks, :extra_marks, :flexible_criteria
    
    setup do
      @admin = users(:olm_admin_1)
      @submission = submissions(:submission_1)
      @grouping = groupings(:grouping_1)
      @assignment = assignments(:assignment_1)
      @result = results(:result_1)
      @released_result = results(:result_4)
      @released_result_flexible = results(:result_flexible_1)
      @mark = marks(:mark_1)
      @extra_mark = extra_marks(:extra_mark_1)
    end
    
    context "GET on :edit with RubricCriterion" do
      context "with 2 partial and 1 released/completed results" do
        setup do
          @result_first = results(:result_1)
          @result_second = results(:result_2)
          # Don't ask me why the third one in the results is
          # called result_4...I think our fixtures got messed up.
          @result_third = results(:result_4)
        end
        context "when editing first result" do
          setup do
            get_as @admin, :edit, :id => @result_first.id
          end
          should "have set next_submission and prev_submission correctly" do
            assert assigns(:next_grouping)
            next_grouping = assigns(:next_grouping)
            assert next_grouping.has_submission?
            next_result = next_grouping.get_submission_used.result
            assert_not_nil next_result
            assert_equal next_result, @result_second
            assert !next_result.released_to_students
            assert_nil assigns(:previous_grouping)
          end
          should_not_set_the_flash 
          should_render_template :edit
          should_respond_with :success 
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
            next_result = next_grouping.get_submission_used.result
            previous_result = previous_grouping.get_submission_used.result
            assert_not_nil next_result
            assert_not_nil previous_result
            assert_equal next_result, @result_third
            assert_equal previous_result, @result_first
            assert next_result.released_to_students
            assert !previous_result.released_to_students
          end
          should_not_set_the_flash 
          should_render_template :edit
          should_respond_with :success 
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
            previous_result = previous_grouping.get_submission_used.result
            assert_not_nil previous_result
            assert_equal previous_result, @result_second
            assert !previous_result.released_to_students
          end
          should_not_set_the_flash 
          should_render_template :edit
          should_respond_with :success 
        end

      end
    end
    
    context "GET on :edit with FlexibleCriterion" do
      setup do
        get_as @admin, :edit, :id => @released_result_flexible.id
      end
      should_not_set_the_flash 
      should_render_template :edit
      should_respond_with :success
    end
    
    context "GET on :next_grouping" do
      
      context "when current grouping has submission" do
        setup do
          Grouping.any_instance.stubs(:has_submission).returns(true)
          get_as @admin, :next_grouping, :id => @grouping.id
        end
        should_respond_with :redirect
      end
      
      context "when current grouping has no submission" do
        setup do
          Grouping.any_instance.stubs(:has_submission).returns(false)
          get_as @admin, :next_grouping, :id => @grouping.id
        end
        should_respond_with :redirect
      end
      
    end
    
    context "GET on :set_released_to_students" do
      setup do
        get_as @admin, :set_released_to_students, :id => @result.id, :value => 'true'
      end
      should_respond_with :success
      should_assign_to :result
    end
    
    context "GET on :update_marking_state" do
      setup do
        get_as @admin, :update_marking_state, :id => @result.id, :marking_state => 'complete'
      end
      should_respond_with :success
      should_assign_to :result
    end
    
    context "GET on :download" do
      setup do
        @file = SubmissionFile.new
      end
      
      context "without file error" do
        setup do
          @file.expects(:filename).once.returns('filename')
          SubmissionFile.expects(:find).with('1').returns(@file)
          ResultsController.any_instance.stubs(:retrieve_file).returns('file content')
          get_as @admin, :download, :select_file_id => 1
        end
        should_not_set_the_flash
        should_respond_with_content_type "application/octet-stream"
        should_respond_with :success
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
          ResultsController.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
          get_as @admin, :download, :select_file_id => 1
        end
        should_set_the_flash_to SAMPLE_ERR_MSG
        should_respond_with :redirect
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
          ResultsController.any_instance.expects(:retrieve_file).once.returns('file content')
          get_as @admin, :codeviewer, :id => @assignment.id, :submission_file_id => 1, :focus_line => 1
        end
        should_not_set_the_flash
        should_assign_to :assignment, :submission_file_id, :focus_line, :file, :result, :annots, :all_annots, :file_contents, :code_type
        should_render_template 'results/common/codeviewer'
        should_respond_with :success
      end
      
      context "with file error" do
        setup do
          ResultsController.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
          get_as @admin, :codeviewer, :id => @assignment.id, :submission_file_id => 1, :focus_line => 1
        end
        should_assign_to :assignment, :submission_file_id, :focus_line, :file, :result, :annots, :all_annots
        should_not_assign_to :file_contents, :code_type
        should_render_template 'shared/_handle_error.rjs'
        should_respond_with :success
        should "pass along the exception's message" do
          # Workaround to assert that the error message made its way to the response
          assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
        end
      end
    end
    
    context "GET on :update_mark" do
      setup do
      end
      
      context "with save error" do
        setup do
          Mark.expects(:find).with('1').returns(@mark)
          @mark.expects(:save).once.returns(false)
          @mark.expects(:errors).once.returns(SAMPLE_ERR_MSG)
          get_as @admin, :update_mark, :mark_id => 1, :mark => 1
        end
        should_render_template 'shared/_handle_error.rjs'
        should_respond_with :success
        should "pass along the \"error hash\"" do
          # Workaround to assert that the error message made its way to the response
          assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
        end
      end
      
      context "without save error" do
        setup do
          get_as @admin, :update_mark, :mark_id => @mark.id, :mark => 1
        end
        should_render_template 'results/marker/_update_mark.rjs'
        should_respond_with :success
      end
      
    end 
    
    context "GET on :view_marks" do
      setup do
        get_as @admin, :view_marks, :id => @assignment.id
      end
      should_render_template '404'
      should_respond_with 404
    end
    
    context "GET on :add_extra_mark" do
      setup do
        get_as @admin, :add_extra_mark, :id => @result.id
      end
      should_assign_to :result
      should_render_template 'results/marker/add_extra_mark'
      should_respond_with :success
    end
    
    context "POST on :add_extra_mark" do
      
      context "with save error" do
        setup do
          extra_mark = ExtraMark.new
          ExtraMark.expects(:new).once.returns(extra_mark)
          extra_mark.expects(:save).once.returns(false)
          post_as @admin, :add_extra_mark, :id => @result.id, :extra_mark => { :extra_mark => 1 }
        end
        should_assign_to :result, :extra_mark
        should_render_template 'results/marker/add_extra_mark_error'
        should_respond_with :success
      end
      
      context "without save error" do
        setup do
          post_as @admin, :add_extra_mark, :id => @result.id, :extra_mark => { :extra_mark => 1 }
        end
        should_assign_to :result, :extra_mark
        should_render_template 'results/marker/insert_extra_mark'
        should_respond_with :success
      end
      
    end

    context "GET on :remove_extra_mark" do
      setup do
        get_as @admin, :remove_extra_mark, :id => @extra_mark.id
      end
      should_not_set_the_flash
      should_assign_to :result
      should_render_template 'results/marker/remove_extra_mark'
      should_respond_with :success      
    end
    
    context "GET on :expand_criteria" do
      setup do
        get_as @admin, :expand_criteria, :aid => @assignment.id
      end
      should_assign_to :assignment, :rubric_criteria
      should_render_template 'results/marker/_expand_criteria.rjs'
      should_respond_with :success
    end
    
    context "GET on :collapse_criteria" do
      setup do
        get_as @admin, :collapse_criteria, :aid => @assignment.id
      end
      should_assign_to :assignment, :rubric_criteria
      should_render_template 'results/marker/_collapse_criteria.rjs'
      should_respond_with :success
    end
    
    context "GET on :expand_unmarked_criteria" do
      setup do
        get_as @admin, :expand_unmarked_criteria, :aid => @assignment.id, :rid => @result.id        
      end
      should_assign_to :assignment, :rubric_criteria, :result, :nil_marks
      should_render_template 'results/marker/_expand_unmarked_criteria'
      should_respond_with :success
    end
    
    context "POST on :update_overall_comment" do
      setup do
        @result = results(:result_5)
        @overall_comment = "A new overall comment!"
        post_as @admin, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @overall_comment}
      end
      should "update the overall comment" do
        @result.reload
        assert_equal @result.overall_comment, @overall_comment
      end
    end
    
  end # An authenticated and authorized admin doing a
  
  context "An authenticated and authorized TA doing a" do
    fixtures :users
    
    setup do
      @ta = users(:ta3)
      @submission = submissions(:submission_1)
      @grouping = groupings(:grouping_1)
      @assignment = assignments(:assignment_1)
      @assignment_flexible = assignments(:flexible_assignment)
      @result = results(:result_5)
      @result_flexible = results(:result_flexible_2)
      @released_result = results(:result_4)
      @mark = marks(:mark_1)
      @extra_mark = extra_marks(:extra_mark_1)
    end
    
    context "GET on :index" do
      setup do
        get_as @ta, :index, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :edit with RubricCriteria" do
      setup do
        get_as @ta, :edit, :id => @result.id
      end
      should_not_set_the_flash 
      should_render_template :edit
      should_respond_with :success
    end
    
    context "GET on :edit with FlexibleCriteria" do
      setup do
        get_as @ta, :edit, :id => @result_flexible.id
      end
      should_not_set_the_flash 
      should_render_template :edit
      should_respond_with :success
    end
    
    context "GET on :next_grouping" do
      
      context "when current grouping has submission" do
        setup do
          Grouping.any_instance.stubs(:has_submission).returns(true)
          get_as @ta, :next_grouping, :id => @grouping.id
        end
        should_respond_with :redirect
      end
      
      context "when current grouping has no submission" do
        setup do
          Grouping.any_instance.stubs(:has_submission).returns(false)
          get_as @ta, :next_grouping, :id => @grouping.id
        end
        should_respond_with :redirect
      end
      
    end
    
    context "GET on :set_released_to_student" do
      setup do
        get_as @ta, :set_released_to_student, :id => 1
      end
      should_respond_with :missing
      should_render_template 404
    end
    
    context "GET on :update_marking_state" do
      setup do
        get_as @ta, :update_marking_state, :id => @result.id, :marking_state => 'complete'
      end
      should_respond_with :success
      should_assign_to :result
    end
    
    context "GET on :download" do
      setup do
        @file = SubmissionFile.new
      end
      
      context "without file error" do
        setup do
          @file.expects(:filename).once.returns('filename')
          SubmissionFile.expects(:find).with('1').returns(@file)
          ResultsController.any_instance.stubs(:retrieve_file).returns('file content')
          get_as @ta, :download, :select_file_id => 1
        end
        should_not_set_the_flash
        should_respond_with_content_type "application/octet-stream"
        should_respond_with :success
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
          ResultsController.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
          get_as @ta, :download, :select_file_id => 1
        end
        should_set_the_flash_to SAMPLE_ERR_MSG
        should_respond_with :redirect
      end
    end
    
    context "GET on :codeviewer" do
      setup do
       @submission_file = submission_files(:student1_ass_5_sub_1)
      end
      
      context "with file reading error" do
        setup do
          # We simulate a file reading error.
          ResultsController.any_instance.expects(:retrieve_file).once.raises(Exception.new(SAMPLE_ERR_MSG))
          get_as @ta, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
        end
        should_assign_to :assignment, :submission_file_id, :focus_line, :file, :result,
                         :annots, :all_annots
        should_not_assign_to :file_contents, :code_type
        should_render_template 'shared/_handle_error.rjs'
        should_respond_with :success
        should "pass along the exception's message" do
          # Workaround to assert that the error message made its way to the response
          assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
        end
      end
      
      context "without error" do
        setup do
          # We don't want to access a real file. 
          ResultsController.any_instance.expects(:retrieve_file).once.returns('file content')
          get_as @ta, :codeviewer, :id => @assignment.id, :submission_file_id => @submission_file.id, :focus_line => 1
        end
        should_assign_to :assignment, :submission_file_id, :focus_line, :file, :result,
                         :annots, :all_annots, :file_contents, :code_type
        should_render_template 'results/common/codeviewer'
        should_respond_with :success
      end
      
    end
    
    context "GET on :update_mark" do
      
      context "with save error" do
        setup do
          Mark.expects(:find).with('1').returns(@mark)
          @mark.expects(:save).once.returns(false)
          @mark.expects(:errors).once.returns(SAMPLE_ERR_MSG)
          get_as @ta, :update_mark, :mark_id => 1, :mark => 1
        end
        should_render_template 'shared/_handle_error.rjs'
        should_respond_with :success
        should "pass along the exception's message" do
          # Workaround to assert that the error message made its way to the response
          assert_match Regexp.new(SAMPLE_ERR_MSG), @response.body
        end
      end
      
      context "without save error" do
        setup do
          get_as @ta, :update_mark, :mark_id => @mark.id, :mark => 1
        end
        should_render_template 'results/marker/_update_mark.rjs'
        should_respond_with :success
      end
      
    end 
    
    context "GET on :view_marks with RubricCriterion" do
      setup do
        get_as @ta, :view_marks, :id => @assignment.id
      end
      should_render_template '404'
      should_respond_with 404
    end
    
    context "GET on :view_marks with FlexibleCriterion" do
      setup do
        get_as @ta, :view_marks, :id => @assignment_flexible.id
      end
      should_render_template '404'
      should_respond_with 404
    end

    context "GET on :add_extra_mark" do
      setup do
        unmarked_result = results(:result_1)
        get_as @ta, :add_extra_mark, :id => unmarked_result.id
      end
      should_assign_to :result
      should_render_template 'results/marker/add_extra_mark'
      should_respond_with :success
    end
    
    context "POST on :add_extra_mark" do
      setup do
        @unmarked_result = results(:result_1)
      end
      
      context "with save error" do
        setup do
          extra_mark = ExtraMark.new
          ExtraMark.expects(:new).once.returns(extra_mark)
          extra_mark.expects(:save).once.returns(false)
          post_as @ta, :add_extra_mark, :id => @unmarked_result.id, :extra_mark => { :extra_mark => 1 }
        end
        should_assign_to :result, :extra_mark
        should_render_template 'results/marker/add_extra_mark_error'
        should_respond_with :success
      end
      
      context "without save error" do
        setup do
          post_as @ta, :add_extra_mark, :id => @unmarked_result.id, :extra_mark => { :extra_mark => 1 }
        end
        should_assign_to :result, :extra_mark
        should_render_template 'results/marker/insert_extra_mark'
        should_respond_with :success
      end
      
    end
    
    context "GET on :remove_extra_mark" do
      setup do
        get_as @ta, :remove_extra_mark, :id => @extra_mark.id
      end
      should_not_set_the_flash
      should_assign_to :result
      should_render_template 'results/marker/remove_extra_mark'
      should_respond_with :success      
    end
    
    context "GET on :expand_criteria" do
      setup do
        get_as @ta, :expand_criteria, :aid => @assignment.id 
      end
      should_assign_to :assignment, :rubric_criteria
      should_render_template 'results/marker/_expand_criteria.rjs'
      should_respond_with :success
    end
    
    context "GET on :collapse_criteria" do
      setup do
        get_as @ta, :collapse_criteria, :aid => @assignment.id
      end
      should_assign_to :assignment, :rubric_criteria
      should_render_template 'results/marker/_collapse_criteria.rjs'
      should_respond_with :success
    end
    
    context "GET on :expand_unmarked_criteria" do
      setup do
        get_as @ta, :expand_unmarked_criteria, :aid => @assignment.id, :rid => @result.id
      end
      should_assign_to :assignment, :rubric_criteria, :result, :nil_marks
      should_render_template 'results/marker/_expand_unmarked_criteria'
      should_respond_with :success
    end
    
    context "POST on :update_overall_comment" do
      setup do
        @result = results(:result_5)
        @overall_comment = "A new overall comment!"
        post_as @ta, :update_overall_comment, :id => @result.id, :result => {:overall_comment => @overall_comment}
      end
      should "update the overall comment" do
        @result.reload
        assert_equal @result.overall_comment, @overall_comment
      end
    end

  end # An authenticated and authorized TA doing a
  
end
