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
    post_as(@admin, :create, :user => {:user_name => 'Essai01', :last_name => 'ESSAI', :first_name => 'essai'})
    assert_response :success
  end

  def test_update
    admin = users(:olm_admin_2)
    post_as(@admin, :update, :user => {:id => admin.id, :last_name => 'ESSAI', :first_name => 'essai'})
    assert_response :redirect
  end


  def test_edit
    admin = users(:olm_admin_2)
    get_as(@admin, :edit, :id => admin.id)
    assert_response :success
  end

end
