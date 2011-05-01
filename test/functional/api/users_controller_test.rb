require File.join(File.dirname(__FILE__), '../../test_helper')
require File.join(File.dirname(__FILE__), '/../../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '../..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

# Tests the users handlers (create, destroy, update, show)
class Api::UsersControllerTest < ActionController::TestCase
  fixtures :all

  context "An GET request to api/users with incorrect authentication" do
    setup do
      debugger
      admin = Admin.make
      base_encoded_md5 = @admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header

      # Get parameters from blueprints
      user_name = Student.make.user_name
      # fire off request
      @res = get("show", {:user_name => user_name})
    end

    should "fail to authenticate" do
      assert_equal("403 Forbidden", @res.status)
    end
  end

#   context "An authenticated GET request to api/users" do
#     setup do
#       # Create dummy user to display
#       user = Student.make
#
#       # Creates admin from blueprints.
#       admin = Admin.make
#       # API key does not come set as nil, it is just a string so reset it.
#       admin.reset_api_key
#       base_encoded_md5 = admin.api_key.strip
#       auth_http_header = "MarkUsAuth #{base_encoded_md5}"
#       @request.env['HTTP_AUTHORIZATION'] = auth_http_header
#
#       # fire off request
#       @res = get("show", {:user_name => user.user_name})
#     end
#
#     should "send the user details in question" do
#
#       # change this to international
#       expected_body = t('user.user_name') + ": " + user.user_name + "\n" +
#                       t('user.user_type') + ": " + user.type + "\n" +
#                       t('user.first_name') + ": " + user.first_name + "\n" +
#                       t('user.last_name') + ": " + user.last_name + "\n"
#       assert_equal("200 OK", @res.status)
#       assert_equal(expected_body, @res.body)
#     end
#   end
#
#   context "An authenticated POST request to api/test_results" do
#
#     setup do
#       admin = Admin.make # Creates admin from blueprint but API key is incorrect
#       admin.reset_api_key
#       base_encoded_md5 = admin.api_key.strip
#       auth_http_header = "MarkUsAuth #{base_encoded_md5}"
#       @request.env['HTTP_AUTHORIZATION'] = auth_http_header
#
#       # Create paramters for request
#       user_name = "ApiTestUser"
#       last_name = "Tester"
#       first_name = "Api"
#       user_type = "admin"
#
#       # fire off request
#       @res = post("create", {:user_name =>, user_name, :last_name => last_name,
#                               :first_name => first_name, :user_type => user_type})
#     end
#
#     should "create a new user " do
#       new_user = User.find_by_user_name(new_user_name)
#       assert !new_user.nil?
#       assert_equal(new_user.last_name, last_name)
#       assert_equal(new_user.last_name, first_name)
#       assert_equal(new_user.type.downcase, user_type)
#     end
#   end
end
