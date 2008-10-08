require File.dirname(__FILE__) + '/../test_helper'

class RubricLevelTest < ActiveSupport::TestCase
  
  fixtures :rubric_criterias

  #Test that Criteria Levels with no names are not valid
  def test_no_name_attr
    no_level_name = create_no_attr(:name)
    assert !no_level_name.valid?
  end

  #Test that Criteria Levels with no description are OK
  def test_no_description_attr_ok
    no_level_description = create_no_attr(:description)
    assert no_level_description.valid?
  end
  
  #Test that Criteria Levels with a description are OK
  def test_description_attr
    with_level_description = create_no_attr(nil)
    assert with_level_description.valid?
  end
  
  #Test that Criteria Levels not assigned to a particular Rubric Criteria are NOT OK
  def test_no_assignment_id
    no_rubric_criteria_id = create_no_attr(:rubric_criteria_id)
    assert !no_rubric_criteria_id.valid?
  end
  
  #Test that Criteria Levels without a level are NOT OK
  def test_no_level
    no_level = create_no_attr(:level)
    assert !no_level.valid?
  end
  
  #Test that Criteria Levels assigned to a non-existant Rubric
  #Criterion are not OK
  def test_rubric_criteria_id_dne
    rubric_criteria_id_dne = create_no_attr(nil)
    rubric_criteria_id_dne.rubric_criteria = RubricCriteria.new
    assert !rubric_criteria_id_dne.save
  end
  
  #Test that Rubric Criteria ID's can only be integers
  def test_rubric_criteria_id_int_only
    int_only = create_no_attr(nil)
    int_only.rubric_criteria_id = 'string'
    assert !int_only.valid?
    
    int_only.rubric_criteria_id = '0.1'
    assert !int_only.valid?
    
    int_only.rubric_criteria_id = 0.1
    assert !int_only.valid?
    
    int_only.rubric_criteria_id = -1
    assert !int_only.valid?
    
  end
  
  #Levels must be an integer greater or equal to 0
  def test_level_range
    level_range = create_no_attr(nil)
    level_range.level = 'string'
    assert !level_range.valid?
    
    level_range.level = -0.1
    assert !level_range.valid?
    
    level_range.level = -1
    assert !level_range.valid?

    level_range.level = 0
    assert level_range.valid?

    level_range.level = 1
    assert level_range.valid?

  end


  # Helper method for test_validate_presence_of to create a level without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_rubric_level = { 
      :name => 'somelevel',
      :description => 'This is my description', 
      :rubric_criteria_id => '1', 
      :level => 1
    }
    
    new_rubric_level.delete(attr) if attr
    RubricLevel.new(new_rubric_level)
  end

end
