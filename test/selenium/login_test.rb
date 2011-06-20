require File.dirname(__FILE__) + '/../selenium_helper'

class LoginTest < Test::Unit::TestCase
  def setup
    @verification_errors = []
    @browser = create_selenium_client("LoginTest");
  end

  def teardown
    @browser.stop
    assert_equal [], @verification_errors
  end

  def test_login_failed
    login_with_user("invalid_user")

    begin
      assert @browser.is_text_present I18n.t('login_failed')
    rescue Test::Unit::AssertionFailedError
      @verification_errors << $!
    end

  end

  def test_login_password_blank
    @browser.open "/"
    @browser.type "user_login", "olm_admin"
    @browser.click "commit"
    @browser.wait_for_page_to_load "30000"

    begin
      assert @browser.is_text_present 'Your password must not be blank.'
    rescue Test::Unit::AssertionFailedError
      @verification_errors << $!
    end

  end

  def test_login_successful
    login_with_user("olm_admin")

    begin
      assert @browser.is_text_present 'Dashboard'
    rescue Test::Unit::AssertionFailedError
      @verification_errors << $!
    end

  end

  def test_no_csrf_on_login
    @browser.open "/"
    assert @browser.is_element_present("authenticity_token")
    assert_equal "", @browser.get_eval("this.browserbot.findElement(\"name=authenticity_token\").value = ''")
    @browser.type "user_login", "olm_admin"
    @browser.type "user_password", "asdf"
    @browser.click "commit"
    @browser.wait_for_page_to_load "30000"
    begin
        assert @browser.is_text_present("Dashboard")
    rescue Test::Unit::AssertionFailedError
        @verification_errors << $!
    end
  end
end
