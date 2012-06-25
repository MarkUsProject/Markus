require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
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
          get :index, :assignment_id => 1
        end
        should respond_with :redirect
      end

      context "on :edit" do
        setup do
          get :edit, :assignment_id => 1, :id => 1
        end
        should respond_with :redirect
      end

      context "on :update" do
        setup do
          put :update, :assignment_id => 1, :id => 1
        end
        should respond_with :redirect
      end

      context "on :new" do
        setup do
          get :new, :assignment_id => 1
        end
        should respond_with :redirect
      end

      context "on :destroy" do
        setup do
          delete :destroy, :assignment_id => 1, :id => 1
        end
        should respond_with :redirect
      end

      context "on :download" do
        setup do
          get :download, :assignment_id => 1
        end
        should respond_with :redirect
      end

      context "on :upload" do
        setup do
          get :upload, :assignment_id => 1
        end
        should respond_with :redirect
      end

      context "on :update_positions" do
        setup do
          get :update_positions, :assignment_id => 1
        end
        should respond_with :redirect
      end

      context "on :move_criterion" do
        setup do
          get :move_criterion, :assignment_id => 1
        end
        should respond_with :redirect
      end

    end # An unauthenticated and unauthorized user doing a GET

    context "An unauthenticated and unauthorized user doing a POST" do

      context "on :index" do
        setup do
          post :index, :assignment_id => 1
        end
        should respond_with :redirect
      end

      context "on :edit" do
        setup do
          post :edit, :assignment_id => 1, :id => 1
        end
        should respond_with :redirect
      end

      context "on :update" do
        setup do
          put :update, :assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :new" do
      setup do
        post :new, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :destroy" do
      setup do
        delete :destroy, :assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download" do
      setup do
        post :download, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :upload" do
      setup do
        post :upload, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :update_positions" do
      setup do
        post :update_positions, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        post :move_criterion, :assignment_id => 1
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
        get_as @admin, :index, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should assign_to :criteria
      should render_template :index
      should respond_with :success
    end

    context "on :edit" do
      setup do
        get_as @admin, :edit, :assignment_id => 1, :id => @criterion.id
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
          get_as @admin,
                 :update,
                 :assignment_id => 1,
                 :id => @criterion.id,
                 :flexible_criterion => {:flexible_criterion_name => 'one', :max => 10}
        end
        should assign_to :criterion
        should render_template 'errors'
        should respond_with :success
      end

      should "be able to save" do
        get_as @admin,
               :update,
               :assignment_id => 1,
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
        get_as @admin, :new, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should_not assign_to :criterion
      should render_template :new
      should respond_with :success
    end

    context "on: download" do
      setup do
        get_as @admin, :download, :assignment_id => @assignment.id
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
        get_as @admin, :upload, :assignment_id => @assignment.id, :upload => {:flexible => ""}
      end
      should assign_to :assignment
      should respond_with :redirect
      should "route properly" do
        assert_recognizes({:controller => "flexible_criteria", :assignment_id => "1", :action => "upload" },
          {:path => "assignments/1/flexible_criteria/upload",  :method => :post})
      end
    end

    should "be able to update_positions" do
      @criterion2 = flexible_criteria(:flexible_criterion_2)
      get_as @admin,
             :update_positions,
             :flexible_criteria_pane_list => [@criterion2.id,
                                              @criterion.id],
             :assignment_id => @assignment.id
      assert render_template ''
      assert_response :success

      c1 = FlexibleCriterion.find(@criterion.id)
      assert_equal 1, c1.position
      c2 = FlexibleCriterion.find(@criterion2.id)
      assert_equal 2, c2.position
    end

    should "be able to move_criterion up" do
      @criterion2 = flexible_criteria(:flexible_criterion_2)
      get_as @admin,
             :move_criterion,
             :assignment_id => @assignment.id,
             :id => @criterion2.id,
             :position => @criterion2.position,
             :direction => :up
      assert render_template ''
      assert_response :success
      @criterion.reload
      @criterion2.reload
      assert_equal 1, @criterion.position
      assert_equal 2, @criterion2.position
    end

    should "be able to move_criterion down" do
      @criterion2 = flexible_criteria(:flexible_criterion_2)
      get_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => :down
      assert render_template ''
      assert_response :success
      @criterion.reload
      @criterion2.reload
      assert_equal 1, @criterion.position
      assert_equal 2, @criterion2.position
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
        post_as @admin, :index, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should assign_to :criteria
      should render_template :index
      should respond_with :success
    end

    context "on :edit" do
      setup do
        post_as @admin, :edit, :assignment_id => 1, :id => @criterion.id
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
          post_as @admin, :new, :assignment_id => @assignment.id, :flexible_criterion => {:flexible_criterion_name => 'first', :max => 10}
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
          post_as @admin, :new, :assignment_id => assignment.id, :flexible_criterion => {:flexible_criterion_name => 'first', :max => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should render_template 'flexible_criteria/create_and_edit'
        should respond_with :success
      end

      context "without error on an assignment that already has criteria" do
        setup do
          post_as @admin, :new, :assignment_id => @assignment.id, :flexible_criterion => {:flexible_criterion_name => 'first', :max => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should render_template 'flexible_criteria/create_and_edit'
        should respond_with :success
      end
    end

    context "on: download" do
      setup do
        post_as @admin, :download, :assignment_id => @assignment.id
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
          post_as @admin, :upload, :assignment_id => @assignment.id, :upload => {:flexible => tempfile}
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
          post_as @admin, :upload, :assignment_id => @assignment.id, :upload => {:flexible => tempfile}
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
          post_as @admin, :upload, :assignment_id => @assignment.id, :upload => {:flexible => tempfile}
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

    should "be able to update_positions" do
      @criterion2 = flexible_criteria(:flexible_criterion_2)
      post_as @admin,
              :update_positions,
              :flexible_criteria_pane_list => [@criterion2.id,
                                               @criterion.id],
              :assignment_id => @assignment.id
      assert render_template ''
      assert_response :success

      c1 = FlexibleCriterion.find(@criterion.id)
      assert_equal 2, c1.position
      c2 = FlexibleCriterion.find(@criterion2.id)
      assert_equal 1, c2.position
    end

    context "on :move_criterion up with 2 criteria" do
      setup do
        @criterion2 = flexible_criteria(:flexible_criterion_2)
        post_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'up'
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
        post_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion3.id, :position => @criterion3.position, :direction => 'up'
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
        post_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'up'
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
        post_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => 'down'
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
        post_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion.id, :position => @criterion.position, :direction => 'down'
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
        post_as @admin, :move_criterion, :assignment_id => @assignment.id, :id => @criterion2.id, :position => @criterion2.position, :direction => 'down'
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
      delete_as @admin, :destroy, :assignment_id => 1, :id => @criterion.id
      assert assign_to :criterion
      assert I18n.t('criterion_deleted_success'), flash[:success]
      assert_response :redirect

      assert_raise ActiveRecord::RecordNotFound do
        FlexibleCriterion.find(@criterion.id)
      end
    end

  end

end
