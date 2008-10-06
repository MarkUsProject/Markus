require File.dirname(__FILE__) + '/../test_helper'

class RubricCriteriaTest < ActiveSupport::TestCase
  
  fixtures :assignments
  
  #Test that Criteria with no names are not valid
  def test_no_name_attr
    no_criteria_name = create_no_attr(:name)
    assert !no_criteria_name.valid?
  end
  
  #Test that Criteria with no description is OK
  def test_no_description_attr_ok
    no_criteria_description = create_no_attr(:description)
    assert no_criteria_description.valid?
  end
  
  #Test that Criteria with a description is OK
  def test_description_attr
    with_criteria_description = create_no_attr(nil)
    assert with_criteria_description.valid?
  end
  
  #Test that Criteria unassigned to Assignment is NOT OK
  def test_no_assignment_id
    no_assignment_id = create_no_attr(:assignment_id)
    assert !no_assignment_id.valid?
  end
  
  #Test that Criteria without weight is NOT OK
  def test_no_weight
    no_weight = create_no_attr(:weight)
    assert !no_weight.valid?
  end
  
  #Test that Criteria assigned to non-existant Assignment
  #is NOT OK
  def test_assignment_id_dne
    assignment_id_dne = create_no_attr(nil)
    assignment_id_dne.assignment = Assignment.new
    assert !assignment_id_dne.save
  end
  
  #Test that Criteria assignment ID's can only be integers
  def test_assignment_id_int_only
    int_only = create_no_attr(nil)
    int_only.assignment_id = 'string'
    assert !int_only.valid?
    
    int_only.assignment_id = '0.1'
    assert !int_only.valid?
    
    int_only.assignment_id = 0.1
    assert !int_only.valid?
    
    int_only.assignment_id = -1
    assert !int_only.valid?
    
  end
  
  #Weights are restricted to a decimal value greater than 0 and less
  #than 1.
  def test_bad_weight_range
    weight_range = create_no_attr(nil)
    weight_range.weight = 'string'
    assert !weight_range.valid?
    
    weight_range.weight = -0.1
    assert !weight_range.valid?
    
    weight_range.weight = 0.0
    assert !weight_range.valid?
    
    weight_range.weight = 1.1
    assert !weight_range.valid?
    
    weight_range.weight = 0.5
    assert weight_range.valid?
    
  end
    
  # Helper method for test_validate_presence_of to create a user without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_rubric_criteria = { 
      :name => 'somecriteria',
      :description => 'This is my description', 
      :assignment_id => '1', 
      :weight => '.25', 
    }
    
    new_rubric_criteria.delete(attr) if attr
    RubricCriteria.new(new_rubric_criteria)
  end

end

