require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'test_helper'
require 'shoulda'
require 'admins_controller'

class AdminsControllerTest < AuthenticatedControllerTest
   fixtures :users
   def setup
     @admin = users(:olm_admin_1)
   end


  # Replace this with your real tests.
   def test_index_without_user
    get :index
    assert_redirected_to :action => "login"
  end

  def test_index
    get_as(@admin, :index)
    assert_response :success
  end


  def test_create
    assert_difference(Admin.count.to_s) do
        post :create, :admin => {:user_name => 'Essai01', :last_name =>
    'ESSAI', :first_name => 'essai'}
  end
    assert_redirect_to post_path(assigns(:admin))
  end
end
