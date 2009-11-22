require File.dirname(__FILE__) + '/../selenium_helper' 

class AssignmentPropertiesTest < Test::Unit::TestCase
  
  def setup
    @verification_errors = []
    @browser = create_selenium_client("AssignmentPropertiesTest");
  end
  
  def teardown
    @browser.stop
    assert_equal [], @verification_errors
  end
  
  def test_no_warning_displayed_when_changing_marking_scheme_on_new_assignment
    login_with_user "olm_admin"
    
    @browser.open '/main/assignments/new'
    @browser.wait_for_page_to_load "30000"
    
    #Assert the warning message is not present when loading the page
    assert_warning_visibility(false)
    
    @browser.click "assignment_marking_scheme_type_flexible"
    assert_warning_visibility(false)
    
    @browser.click "assignment_marking_scheme_type_rubric"
    assert_warning_visibility(false)

  end
  
  def test_warning_when_changing_from_flexible_to_rubric
     login_with_user "olm_admin"
     
     @browser.open '/main/assignments'
     @browser.wait_for_page_to_load "30000"
     
     @browser.click "link=exact:How flexible can you get?:"
     @browser.wait_for_page_to_load "30000"
     
     #Assert the warning message is not present when loading the page
     assert_warning_visibility(false)
     
     @browser.click "assignment_marking_scheme_type_flexible"
     assert_warning_visibility(false)
     
     @browser.click "assignment_marking_scheme_type_rubric"
     assert_warning_visibility(true)
     
     @browser.click "assignment_marking_scheme_type_flexible"
     assert_warning_visibility(false)
   end
   
   def test_warning_when_changing_from_rubric_to_flexible
      login_with_user "olm_admin"

      @browser.open '/main/assignments'
      @browser.wait_for_page_to_load "30000"

      @browser.click "link=exact:Captain Sparrow:"
      @browser.wait_for_page_to_load "30000"

      #Assert the warning message is not present when loading the page
      assert_warning_visibility(false)

      @browser.click "assignment_marking_scheme_type_rubric"
      assert_warning_visibility(false)

      @browser.click "assignment_marking_scheme_type_flexible"
      assert_warning_visibility(true)
      
      @browser.click "assignment_marking_scheme_type_rubric"
      assert_warning_visibility(false)
    end
  
  def assert_warning_visibility(isVisible)
    begin
    assert_equal(isVisible, @browser.is_visible('marking_scheme_notice'))
    rescue Test::Unit::AssertionFailedError
      @verification_errors << $!
    end
  end
end