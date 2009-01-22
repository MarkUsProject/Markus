require File.dirname(__FILE__) + '/../test_helper'
require 'rubrics_controller'
require 'fastercsv'

class RubricsControllerTest < ActionController::TestCase
 
  def set_up
    @controller = RubricsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    # need to login before testing!
    @admin = users(:admin)
    @request.session['uid'] = @admin.id

  end
  
  # Test criterion creation
  
  def test_add_criterion
    criterion = @controller.add_criterion
    assert_not_nill criterion
    assert_equals "New Criterion 1", criterion.name;
  end
  
  # TODO Test update criterion
  def test_update_criterion
   
  end 
  
  # TODO Test update level
  def test_update_level
    
  end
  
  # TODO Check csv upload works correctly
  def test_csv_upload
    
  end
  
  # Check invalid csv lines are handled correctly
  def test_invalid_csv
    criterion = @controller.add_csv_criterion("Correctness,15")
    assert_nil criterion, "Missing field"
    criterion = @controller.add_csv_criterion("Style,5,Code Style,Some Extra field here")
    assert_nil criterion, "Extra field"
    criterion = @controller.add_csv_criterion("Documentation,100percent,Code was thoroughly commented")
    assert_nil criterion, "Weight had a non-numeric value"
  end

end
