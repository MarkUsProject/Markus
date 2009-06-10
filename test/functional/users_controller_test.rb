require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

class UsersControllerTest < ActionController::TestCase

  def setup
    @controller = UsersController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
   
  
  # Parser Tests --------------------------------------------------------
  # test for valid and invalid inputs
  # TODO cannot test upload classlist, probably because we need to login first.
  
  def test_one_valid_classlist
    
    #cl_file = "/classlist/valid_line.csv"
    # post :update_classlist, 
    #  { :classlist => fixture_file_upload(cl_file, "text/plain") },
    #  { :uid => users(:admin).id } # simulate login
    
    #assert_not_nil flash[:upload_notice], "Test one valid csv line"
    #user = User.find_by_user_number('764733017')
    #assert_not_nil user
    #assert_equal 'g8bergal', user.user_name
    
    
    #assert_nil @controller.add_student("c8debuss,Debussy,Claude"), "missing attribute"
    
    # invalid user numbers non-9 all-digit numbers
    # no checks done on other attributes
    #user = @controller.add_student("c8debuss,2,Debussy,Claude")
    #assert_nil user, "1 digit user number"
    
    #user = @controller.add_student("c8jongen,allstring,Jongen,Joseph")
    #assert_nil user, "non-digit 9length user number"
    
    #user = @controller.add_student("c6stenha,123456b89,Stenhammar,Wilhelm")
    #assert_nil user, "alphanumeric 9-length user number"
  end
  
  
  # Test for uncommon patterns in input that are suppose to be valid
  def name_special_cases
    user = @controller.add_user("g5d'indy,d'Indy,Vincent")
    assert_not_nil user, "Apostrophe in names"
    assert_equal "Vincent", User.find_by_user_name("g5d'indy").first_name
    
    user = @controller.add_user("c5zemlin,Zemlinsky,Alexander von")
    assert_not_nil user, "Spaces in names"
    assert_equal "Alexander von", User.find_by_user_name("c5zemlin").first_name
  end
  
  
  # Test for misconstructed csv formats
  def csv_format
    user = @controller.add_user("c6malipi,Malipiero,Gian Francesco,unneeded field")
    assert_not_nil user, "Extra field"
  end

  
end
