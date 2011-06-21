require 'test_helper'
require 'rubygems'
gem "selenium-client", ">=1.2.15"
require 'selenium/client'

def create_selenium_client(context)
  # Beware - Chrome is not Google Chrome, it is the core of firefox
  @browser = Selenium::Client::Driver.new("localhost", 4444, "*chrome", "http://localhost:3001/", 100000);
  @browser.start
  @browser.set_context(context)
  return @browser
end

def login_with_user(user_name)
  @browser.open "/"
  @browser.type "user_login", user_name
  @browser.type "user_password", "a"
  @browser.click "commit"
  @browser.wait_for_page_to_load "30000"
end


