require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'mocha'

class FlexibleCriteriaControllerTest < AuthenticatedControllerTest

  fixtures :all

  FLEXIBLE_CRITERIA_CSV_STRING = "criterion1,10.0,\"description1, for criterion 1\"\ncriterion2,10.0,\"description2, \"\"with quotes\"\"\"\ncriterion3,1.6,description3!\n"
  FLEXIBLE_CRITERIA_UPLOAD_CSV_STRING = "criterion3,10.0,\"description3, for criterion 3\"\ncriterion4,10.0,\"description4, \"\"with quotes\"\"\"\n"
  FLEXIBLE_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING = "criterion5\ncriterion6\n"
  FLEXIBLE_CRITERIA_PARTIAL_UPLOAD_CSV_STRING = "criterion7,5.0\ncriterion8,7.5\n"

  context "An unauthenticated and unauthorized user doing a GET" do

    context "on :index" do
      setup do
        get :index, :id => 1
      end
      should respond_with :redirect
    end

    context "on :edit" do
      setup do
        get :edit, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update" do
      setup do
        get :update, :id => 1
      end
      should respond_with :redirect
    end

    context "on :new" do
      setup do
        get :new, :id => 1
      end
      should respond_with :redirect
    end

    context "on :delete" do
      setup do
        get :delete, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download" do
      setup do
        get :download, :id => 1
      end
      should respond_with :redirect
    end

    context "on :upload" do
      setup do
        get :upload, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_positions" do
      setup do
        get :update_positions, :id => 1
      end
      should respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        get :move_criterion, :id => 1
      end
      should respond_with :redirect
    end

  end # An unauthenticated and unauthorized user doing a GET

  context "An unauthenticated and unauthorized user doing a POST" do

    context "on :index" do
      setup do
        post :index, :id => 1
      end
      should respond_with :redirect
    end

    context "on :edit" do
      setup do
        post :edit, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update" do
      setup do
        post :update, :id => 1
      end
      should respond_with :redirect
    end

    context "on :new" do
      setup do
        post :new, :id => 1
      end
      should respond_with :redirect
    end

    context "on :delete" do
      setup do
        post :delete, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download" do
      setup do
        post :download, :id => 1
      end
      should respond_with :redirect
    end

    context "on :upload" do
      setup do
        post :upload, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_positions" do
      setup do
        post :update_positions, :id => 1
      end
      should respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        post :move_criterion, :id => 1
      end
      should respond_with :redirect
    end

  end # An unauthenticated and unauthorized user doing a POST

  context "An authenticated and authorized admin doing a GET" do
    fixtures :users, :assignments, :flexible_criteria, :marks, :results

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:flexible_assignment)
      @criterion = flexible_criteria(:flexible_criterion_1)
    end

    context "on :index" do
      setup do
        get_as @admin, :index, :id => @assignment.id
      end
      should assign_to :assignment
      should assign_to :criteria
      should render_template :index
      should respond_with :success
    end

    context "on :edit" do
      setup do
        get_as @admin, :edit, :id => @criterion.id
      end
      should assign_to :criterion
      should render_template :edit
      should respond_with :success
    end

    context "on :update" do

      context "with save errors" do
        setup do
          FlexibleCriterion.any_instance.expects(:save).once.returns(false)
          FlexibleCriterion.any_instance.expects(:errors).once.returns('error msg')
          get_as @admin, :update, :id => @criterion.id, :flexible_criterion => {:flexible_criterion_name => 'one', :max => 10}
        end
        should assign_to :criterion
        should render_template 'errors'
        should respond_with :success
      end

      should "be able to save" do
        get_as @admin,
               :update,
               :id => @criterion.id,
               :flexible_criterion => {:flexible_criterion_name => 'one',
                                       :max => 10}
        assert flash[:success], I18n.t('criterion_saved_success')
        assert assign_to :criterion
        assert render_template :update
      end
    end

    context "on :new" do
      setup do
        get_as @admin, :new, :id => @assignment.id
      end
      should assign_to :assignment
      should_not assign_to :criterion
      should render_template :new
      should respond_with :success
    end

    context "on: download" do
      setup do
        get_as @admin, :download, :id => @assignment.id
      end
      should assign_to :assignment
      should respond_with_content_type 'text/csv'
      should respond_with :success
      should "respond with appropriate content" do
        assert_equal FLEXIBLE_CRITERIA_CSV_STRING, @response.body
      end
    end

    context "on :upload" do
      setup do
        get_as @admin, :upload, :id => @assignment.id, :upload => {:flexible => ""}
      end
      should assign_to :assignment
      should respond_with :redirect
    end

    context "on :update_positions" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        get_as @admin, :update_positions, :flexible_criteria_pane_list => [@criterion2.id, @criterion.id], :aid => @assignment.id
      end
      should render_template ''
      should respond_with :success

      should "not have adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 2, c2.position
      end
    end

    context "on :move_criterion up" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        get_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => :up
      end
      should render_template ''
      should respond_with :success

      should "not have adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 2, c2.position
      end
    end

    context "on :move_criterion down" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        get_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => :down
      end
      should render_template ''
      should respond_with :success

      should "not have adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 2, c2.position
      end
    end

  end # An authenticated and authorized admin doing a GET

  context "An authenticated and authorized admin doing a POST" do
    fixtures :users, :assignments, :flexible_criteria, :marks, :results

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:flexible_assignment)
      @criterion = flexible_criteria(:flexible_criterion_1)
    end

    context "on :index" do
      setup do
        post_as @admin, :index, :id => @assignment.id
      end
      should assign_to :assignment
      should assign_to :criteria
      should render_template :index
      should respond_with :success
    end

    context "on :edit" do
      setup do
        post_as @admin, :edit, :id => @criterion.id
      end
      should assign_to :criterion
      should render_template :edit
      should respond_with :success
    end

    context "on :new" do
      context "with save error" do
        setup do
          FlexibleCriterion.any_instance.expects(:save).once.returns(false)
          FlexibleCriterion.any_instance.expects(:errors).once.returns('error msg')
          post_as @admin, :new, :id => @assignment.id, :flexible_criterion => {:flexible_criterion_name => 'first', :max => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should assign_to :errors
        should render_template 'flexible_criteria/add_criterion_error'
        should respond_with :success
      end

      context "without error on an assignment as the first criterion" do
        setup do
          assignment = assignments(:flexible_assignment_without_criterion)
          post_as @admin, :new, :id => assignment.id, :flexible_criterion => {:flexible_criterion_name => 'first', :max => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should render_template 'flexible_criteria/create_and_edit'
        should respond_with :success
      end

      context "without error on an assignment that already has criteria" do
        setup do
          post_as @admin, :new, :id => @assignment.id, :flexible_criterion => {:flexible_criterion_name => 'first', :max => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should render_template 'flexible_criteria/create_and_edit'
        should respond_with :success
      end
    end

    context "on: download" do
      setup do
        post_as @admin, :download, :id => @assignment.id
      end
      should assign_to :assignment
      should respond_with_content_type 'text/csv'
      should respond_with :success
      should "respond with appropriate content" do
        assert_equal FLEXIBLE_CRITERIA_CSV_STRING, @response.body
      end
    end

    context "on :upload" do
      context "with file containing incomplete records" do
        setup do
          tempfile = Tempfile.new('flexible_csv')
          tempfile << FLEXIBLE_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING
          tempfile.rewind
          post_as @admin, :upload, :id => @assignment.id, :upload => {:flexible => tempfile}
        end
        should assign_to :assignment
        should set_the_flash
        should respond_with :redirect
      end

      context "with file containing partial records" do
        setup do
          tempfile = Tempfile.new('flexible_csv')
          tempfile << FLEXIBLE_CRITERIA_PARTIAL_UPLOAD_CSV_STRING
          tempfile.rewind
          post_as @admin, :upload, :id => @assignment.id, :upload => {:flexible => tempfile}
        end
        should assign_to :assignment
        should set_the_flash
        should respond_with :redirect
      end

      context "with file containing full records" do
        setup do
          FlexibleCriterion.destroy_all
          tempfile = Tempfile.new('flexible_csv')
          tempfile << FLEXIBLE_CRITERIA_UPLOAD_CSV_STRING
          tempfile.rewind
          post_as @admin, :upload, :id => @assignment.id, :upload => {:flexible => tempfile}
          @assignment.reload
          @flexible_criteria = @assignment.flexible_criteria
        end
        should assign_to :assignment
        should set_the_flash
        should respond_with :redirect
        should "have successfully uploaded criteria" do
            assert_equal 2, @assignment.flexible_criteria.size
        end
        should "keep ordering of uploaded criteria" do
            assert_equal "criterion3", @flexible_criteria[0].flexible_criterion_name
            assert_equal 1, @flexible_criteria[0].position
            assert_equal "criterion4", @flexible_criteria[1].flexible_criterion_name
            assert_equal 2, @flexible_criteria[1].position
        end
      end
    end

    context "on :update_positions" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        post_as @admin, :update_positions, :flexible_criteria_pane_list => [@criterion2.id, @criterion.id], :aid => @assignment.id
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
      end
    end

    context "on :move_criterion up with 2 criteria" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'up'
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
      end
    end

    context "on :move_criterion up with 3 criteria from bottom" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        @criterion3 = flexible_criteria(:flexible_criterion_3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion3.id, :position => @criterion3.position, :direction => 'up'
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 3, c2.position
        c3 = FlexibleCriterion.find(@criterion3.id)
        assert_equal 2, c3.position
      end
    end

    context "on :move_criterion up with 3 criteria from middle" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        @criterion3 = flexible_criteria(:flexible_criterion_3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'up'
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
        c3 = FlexibleCriterion.find(@criterion3.id)
        assert_equal 3, c3.position
      end
    end

    context "on :move_criterion down with 2 criteria" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => 'down'
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
      end
    end

    context "on :move_criterion down with 3 criteria from top" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        @criterion3 = flexible_criteria(:flexible_criterion_3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => 'down'
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 2, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 1, c2.position
        c3 = FlexibleCriterion.find(@criterion3.id)
        assert_equal 3, c3.position
      end
    end

    context "on :move_criterion down with 3 criteria from middle" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        @criterion3 = flexible_criteria(:flexible_criterion_3)
        post_as @admin, :move_criterion, :aid => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'down'
      end
      should render_template ''
      should respond_with :success

      should "have appropriately adjusted positions" do
        c1 = FlexibleCriterion.find(@criterion.id)
        assert_equal 1, c1.position
        c2 = FlexibleCriterion.find(@criterion2.id)
        assert_equal 3, c2.position
        c3 = FlexibleCriterion.find(@criterion3.id)
        assert_equal 2, c3.position
      end
    end

  end # An authenticated and authorized admin doing a POST

  context "An authenticated and authorized admin doing a DELETE" do
    fixtures :users, :assignments, :flexible_criteria, :marks, :results

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:flexible_assignment)
      @criterion = flexible_criteria(:flexible_criterion_1)
    end


    should "be able to delete the criterion" do
      delete_as @admin, :delete, :id => @criterion.id
      assert assign_to :criterion
      assert I18n.t('criterion_deleted_success'), flash[:success]
      assert respond_with :success

      assert_raise ActiveRecord::RecordNotFound do
        FlexibleCriterion.find(@criterion.id)
      end
    end

  end

end
