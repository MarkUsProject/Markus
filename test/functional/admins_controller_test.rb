require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')

require 'shoulda'
require 'admins_controller'

class AdminsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  def teardown
    destroy_repos
  end

  context "No user" do
    should "redirect to the index" do
      get :index
      assert_redirected_to :action => "login", :controller => "main"
    end
  end

  context "An admin" do
    setup do
      @admin = Admin.make
    end

    should "respond with success on index" do
      get_as(@admin, :index)
      assert_response :success
    end

    should "be able to create Admin" do
       post_as(@admin,
               :create,
               :user => {:user_name => 'jdoe',
                         :last_name => 'Doe',
                         :first_name => 'Jane'})
       assert_redirected_to :action => "index"
       a = Admin.find_by_user_name('jdoe')
       assert_not_nil a
    end
    
    context "with a second user" do
      setup do
        @admin2 = Admin.make
      end

      should "be able to update" do
        post_as(@admin,
                :update,
                :user => {:id => @admin2.id,
                          :last_name => 'John',
                          :first_name => 'Doe'})
        assert_response :redirect
      end

      should "be able to edit" do
        get_as(@admin, :edit, :id => @admin2.id)
        assert_response :success
      end
    end
  end
end
