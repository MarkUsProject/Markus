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
      get_as @admin, :index
      assert_response :success
    end

    should "be able to create Admin" do
       post_as @admin,
               :create,
               :user => {:user_name => 'jdoe',
                         :last_name => 'Doe',
                         :first_name => 'Jane'}
       a = Admin.find_by_user_name('jdoe')
       assert_redirected_to :action => "index"
    end

    context "with a second user" do
      setup do
        @admin2 = Admin.make
      end

      should "be able to update" do
        put_as @admin,
               :update,
               :id => @admin2.id,
               :user => {:last_name => 'John',
                         :first_name => 'Doe'}

        assert_redirected_to :action => "index"
        assert_equal I18n.t("admins.success",
                            :user_name => @admin2.user_name),
                     flash[:edit_notice]
      end

      should "be able to edit" do
        get_as @admin, :edit, :id => @admin2.id
        assert_response :success
        assert_not_nil assigns(:user)
      end
    end
  end
end
