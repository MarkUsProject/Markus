require File.dirname(__FILE__) + '/../test_helper'
require 'rubrics_controller'
require 'fastercsv'

class RubricsControllerTest < ActionController::TestCase
 
  def set_up
    @controller = RubricsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    @admin = users(:admin)
    @request.session['uid'] = @admin.id
  end

  def test_index
    #this doesn't work...
    #assignment = assignments(:a1)
    #get :index, {}, {:id=>assignment.id}
    #assert_response :success
  end

  # Test criterion creation  
  def test_add_criterion
    #criterion = @controller.add_criterion()
    #@request
    #assert_not_nil criterion
    #assert_equals "New Criterion 1", criterion.name
  end
  
  # Check csv upload works correctly
  def test_csv_upload
    assignment = assignments(:a1)
    levels = ["Level 0","Level 1","Level 2","Level 3","Level 4"]
    values = ["Correctness","15"]
    criterion = @controller.add_csv_criterion(values, levels, assignment);
    assert_not_nil criterion
    #check levels were added
    for i in [0, 1, 2, 3, 4]
      assert_equal criterion['level_' + i.to_s + '_name'], 'Level ' + i.to_s
      assert_nil criterion['level_' + i.to_s + '_description']
    end

    #test that descriptions are saved correctly
    values2 = ["Documentation","10","No Comments",
      "Few Comments","Some comments","Many Comments","Everything is commented"]

    criterion = @controller.add_csv_criterion(values2, levels, assignment);
    assert_not_nil criterion
    #check descriptions were saved
    for i in [0, 1, 2, 3, 4]
      assert_equal criterion['level_' + i.to_s + '_description'], values2[i+3]
    end

  end
  
  # Check invalid csv lines are handled correctly
  def test_invalid_csv
    assignment = assignments(:a1)
    levels = ["Level 1", "Level2", "Level3"]
    values1 = ["Correctness"]
    criterion = @controller.add_csv_criterion(values1, levels, assignment)
    assert_nil criterion, "Missing field"

    values2 = ["Documentation","100percent"]
    criterion = @controller.add_csv_criterion(values2, levels, assignment)
    assert_nil criterion, "Weight had a non-numeric value"
  end

  def test_special_case_csv
    assignment = assignments(:a1)
    levels = ["Level 1", "Level2", "Level3"]

    values = ["Documentation","10","No Comments",
      "Few Comments","Some comments","Many Comments","Everything is commented",
      "Some Extra field here"]
    #extra fields should just be ignored
    criterion = @controller.add_csv_criterion(values, levels, assignment)
    assert_not_nil criterion, "Extra field - should still be ok"
  end

  # Test update criterion
  def test_update_criterion
    criterion = create_dummy_criterion

    #post :update_criterion, {:criterion_id=>criterion.id,:update_type=>'name',
    #  :new_value=>"New Name"}
    #assert_equal criterion.name, "New Name"
  end

  # Test update level
  def test_update_level
    criterion = create_dummy_criterion

  end

  def create_dummy_criterion
    assignment = assignments(:a1)
    levels = ["Level 0","Level 1","Level 2","Level 3","Level 4"]
    values = ["Documentation","10","No Comments",
      "Few Comments","Some comments","Many Comments","Everything is commented",
      "Some Extra field here"]
    return @controller.add_csv_criterion(values, levels, assignment);
  end

end
