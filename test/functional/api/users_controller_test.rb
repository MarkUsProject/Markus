require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

# Tests the users handlers (create, destroy, update, show)
class Api::UsersControllerTest < ActionController::TestCase

  fixtures :all

  context "An GET request to api/users with incorrect authentication" do
    setup do
      admin = Admin.make
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header

      # Get parameters from blueprints
      user_name = admin.user_name
      # fire off request
      @res = get("show", {:user_name => user_name})
    end

    should "fail to authenticate" do
      assert_equal("403 Forbidden\n", @res.body)
    end

  context "An authenticated GET request to api/users" do
    setup do
      # Creates admin from blueprints.
      admin = Admin.make
      # API key does not come set as nil, it is just a string so reset it.
      admin.reset_api_key
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header

      # Get parameters from blueprints
      user_name = admin.user_name
      # fire off request
      @res = get("show", {:user_name => user_name})
    end

      should "send the user details in question" do
      user = admin
      # change this to international
      expected_body = "\nUsername: " + user.user_name +
                      "\nType: " + user.type +
                      "\nFirst Name: " + user.first_name +
                      "\nLast Name: " + user.last_name
      assert_equal(expected_body, @res.body)
    end
  end

  context "An authenticated POST request to api/test_results" do

    setup do
      admin = Admin.make # Creates admin from blueprint but API key is incorrect
      admin.reset_api_key
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header

      # Create paramters for request


      # fire off request
      @res = post("create", {:group_name => group_name, :assignment => a_short_identifier,
                             :filename => @filename, :file_content => @file_content})
    end
  end
end
