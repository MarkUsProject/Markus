require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'mocha'
require 'machinist'

class RubricsControllerTest < AuthenticatedControllerTest
  
  fixtures :all
  
  RUBRIC_CRITERIA_CSV_STRING = "Algorithm Design,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Documentation,2.7,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Testing,2.2,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Correctness,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n"
  RUBRIC_CRITERIA_UPLOAD_CSV_STRING = "criterion 5,1.0,l0,l1,l2,l3,l4,d0,d1,d2,d3,d4\n"
  RUBRIC_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING = "criterion 5\ncriterion 6\n"

  context "An unauthenticated and unauthorized user doing a GET" do
    
    context "on :index" do
      setup do
        get :index, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :edit" do
      setup do
        get :edit, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update" do
      setup do
        get :update, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :new" do
      setup do
        get :new, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :delete" do
      setup do
        get :delete, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :download" do
      setup do
        get :download, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :upload" do
      setup do
        get :upload, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update_positions" do
      setup do
        get :update_positions, :id => 1
      end
      should_respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        get :move_criterion, :id => 1
      end
      should_respond_with :redirect
    end

  end # An unauthenticated and unauthorized user doing a GET
  
  context "An unauthenticated and unauthorized user doing a POST" do
    
    context "on :index" do
      setup do
        post :index, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :edit" do
      setup do
        post :edit, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update" do
      setup do
        post :update, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :new" do
      setup do
        post :new, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :delete" do
      setup do
        post :delete, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :download" do
      setup do
        post :download, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :upload" do
      setup do
        post :upload, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update_positions" do
      setup do
        post :update_positions, :id => 1
      end
      should_respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        post :move_criterion, :id => 1
      end
      should_respond_with :redirect
    end

  end # An unauthenticated and unauthorized user doing a POST
  
  context "An authenticated and authorized admin doing a GET" do
    fixtures :users, :assignments, :rubric_criteria, :marks, :results
    
    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @criterion = rubric_criteria(:c1)
    end
    
    context "on :index" do
      setup do
        get_as @admin, :index, :id => @assignment.id
      end
      should_assign_to :assignment, :criteria
      should_render_template :index
      should_respond_with :success
    end
    
    context "on :edit" do
      setup do
        get_as @admin, :edit, :id => @criterion.id
      end
      should_assign_to :criterion
      should_render_template :edit
      should_respond_with :success
    end
    
    context "on :update" do
      
      context "with save errors" do
        setup do
          RubricCriterion.any_instance.expects(:save).once.returns(false)
          RubricCriterion.any_instance.expects(:errors).once.returns('error msg')
          get_as @admin, :update, :id => @criterion.id, :rubric_criterion => {:rubric_criterion_name => 'one', :weight => 10}
        end
        should_assign_to :criterion
        should_render_template 'errors'
        should_respond_with :success
      end
      
      context "without save errors" do
        setup do
          get_as @admin, :update, :id => @criterion.id, :rubric_criterion => {:rubric_criterion_name => 'one', :weight => 10}
        end
        should_assign_to :criterion
        should_set_the_flash_to I18n.t('criterion_saved_success')
        should_render_template :update
      end
    end
    
    context "on :new" do
      setup do
        get_as @admin, :new, :id => @assignment.id
      end
      should_assign_to :assignment
      should_not_assign_to :criterion
      should_render_template :new
      should_respond_with :success
    end
    
    context "on: download" do
      setup do
        get_as @admin, :download, :id => @assignment.id
      end
      should_assign_to :assignment
      should_respond_with_content_type 'text/csv'
      should_respond_with :success
      should "respond with appropriate content" do
        assert_equal RUBRIC_CRITERIA_CSV_STRING, @response.body
      end
    end
    
    context "on :upload" do
      setup do
        get_as @admin, :upload, :id => @assignment.id, :upload => {:rubric => ""}
      end
      should_assign_to :assignment
      should_respond_with :redirect
    end
    
    context "on :update_positions" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        get_as @admin, :update_positions, :rubric_criteria_pane_list => [@criterion2.id, @criterion.id], :aid => @assignment.id
      end
      should_render_template ''
      should_respond_with :success
      
      should "not have adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 2, c2.position
      end
    end

    context "on :move_criterion up" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        get_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => :up
      end
      should_render_template ''
      should_respond_with :success

      should "not have adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 2, c2.position
      end
    end

    context "on :move_criterion down" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        get_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => :up
      end
      should_render_template ''
      should_respond_with :success

      should "not have adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 2, c2.position
      end
    end
    
  end # An authenticated and authorized admin doing a GET
  
  context "An authenticated and authorized admin doing a POST" do
    fixtures :users, :assignments, :rubric_criteria, :marks, :results
    
    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @criterion = rubric_criteria(:c1)
    end
    
    context "on :index" do
      setup do
        post_as @admin, :index, :id => @assignment.id
      end
      should_assign_to :assignment, :criteria
      should_render_template :index
      should_respond_with :success
    end
    
    context "on :edit" do
      setup do
        post_as @admin, :edit, :id => @criterion.id
      end
      should_assign_to :criterion
      should_render_template :edit
      should_respond_with :success
    end
    
    context "on :new" do      
      context "with save error" do
        setup do
          RubricCriterion.any_instance.expects(:save).once.returns(false)
          RubricCriterion.any_instance.expects(:errors).once.returns('error msg')
          post_as @admin, :new, :id => @assignment.id, :rubric_criterion => {:rubric_criterion_name => 'first', :weight => 10}
        end
        should_assign_to :assignment, :criterion, :errors
        should_render_template 'rubrics/add_criterion_error'
        should_respond_with :success
      end
      
      context "without error on an assignment as the first criterion" do
        setup do
          assignment = assignments(:assignment_3)
          post_as @admin, :new, :id => assignment.id, :rubric_criterion => {:rubric_criterion_name => 'first', :weight => 10}
        end
        should_assign_to :assignment, :criterion
        should_render_template 'rubrics/create_and_edit'
        should_respond_with :success
      end
      
      context "without error on an assignment that already has criteria" do
        setup do
          post_as @admin, :new, :id => @assignment.id, :rubric_criterion => {:rubric_criterion_name => 'first', :weight => 10}
        end
        should_assign_to :assignment, :criterion
        should_render_template 'rubrics/create_and_edit'
        should_respond_with :success
      end      
    end
    
    context "on: download" do
      setup do
        post_as @admin, :download, :id => @assignment.id
      end
      should_assign_to :assignment
      should_respond_with_content_type 'text/csv'
      should_respond_with :success
      should "respond with appropriate content" do
        assert_equal RUBRIC_CRITERIA_CSV_STRING, @response.body
      end
    end
    
    context "on :upload" do      
      context "with file containing incomplete records" do
        setup do
          tempfile = Tempfile.new('rubric_csv')
          tempfile << RUBRIC_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING
          tempfile.rewind          
          post_as @admin, :upload, :id => @assignment.id, :upload => {:rubric => tempfile}
        end
        should_assign_to :assignment
        should_set_the_flash_to :error => I18n.t('csv_invalid_lines'),
                                :invalid_lines => ["criterion 5: " + I18n.t('criteria.error.incomplete_row'),
                                                   "criterion 6: " + I18n.t('criteria.error.incomplete_row')]
        should_respond_with :redirect
      end
      
      context "with file containing full records" do
        setup do
          tempfile = Tempfile.new('rubric_csv')
          tempfile << RUBRIC_CRITERIA_UPLOAD_CSV_STRING
          tempfile.rewind          
          post_as @admin, :upload, :id => @assignment.id, :upload => {:rubric => tempfile}
        end
        should_assign_to :assignment
        should_set_the_flash_to I18n.t('rubric_criteria.upload.success', :nb_updates => 1)
        should_respond_with :redirect
      end
    end
    
    context "on :update_positions" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        post_as @admin, :update_positions, :rubric_criteria_pane_list => [@criterion2.id, @criterion.id], :aid => @assignment.id
      end
      should_render_template ''
      should_respond_with :success
      
      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
      end
    end

    context "on :move_criterion up with 2 criteria" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'up'
      end
      should_render_template ''
      should_respond_with :success

      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
      end
    end

    context "on :move_criterion up with 3 criteria from bottom" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        @criterion3 = rubric_criteria(:c3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion3.id, :position => @criterion3.position, :direction => 'up'
      end
      should_render_template ''
      should_respond_with :success

      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 3, c2.position
        c3 = RubricCriterion.find(@criterion3.id)
        assert_equal 2, c3.position
      end
    end

    context "on :move_criterion up with 3 criteria from middle" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        @criterion3 = rubric_criteria(:c3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'up'
      end
      should_render_template ''
      should_respond_with :success

      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
        c3 = RubricCriterion.find(@criterion3.id)
        assert_equal 3, c3.position
      end
    end

    context "on :move_criterion down with 2 criteria" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => 'down'
      end
      should_render_template ''
      should_respond_with :success

      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
      end
    end

    context "on :move_criterion down with 3 criteria from top" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        @criterion3 = rubric_criteria(:c3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => 'down'
      end
      should_render_template ''
      should_respond_with :success

      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
        c3 = RubricCriterion.find(@criterion3.id)
        assert_equal 3, c3.position
      end
    end

    context "on :move_criterion down with 3 criteria from middle" do
      setup do
        @criterion2 = rubric_criteria(:c2)
        @criterion3 = rubric_criteria(:c3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'down'
      end
      should_render_template ''
      should_respond_with :success

      should "have appropriately adjusted positions" do
        c1 = RubricCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = RubricCriterion.find(@criterion2.id)
        assert_equal 3, c2.position
        c3 = RubricCriterion.find(@criterion3.id)
        assert_equal 2, c3.position
      end
    end
    
  end # An authenticated and authorized admin doing a POST
  
  context "An authenticated and authorized admin doing a DELETE" do
    fixtures :users, :assignments, :rubric_criteria, :marks, :results
    
    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @criterion = rubric_criteria(:c1)
      @mark = marks(:mark_11)
    end
    
    context "on :delete" do
      setup do
        delete_as @admin, :delete, :id => @criterion.id
      end
      should_assign_to :criterion
      should_set_the_flash_to I18n.t('criterion_deleted_success')
      should_respond_with :success
      
      should "effectively destroy the criterion" do
        assert_raise ActiveRecord::RecordNotFound do 
          RubricCriterion.find(@criterion.id)
        end
      end
      should "effectively destroy the marks" do
        assert_raise ActiveRecord::RecordNotFound do 
          Mark.find(@mark.id)
        end
      end
    end
    
  end

end
