require File.dirname(__FILE__) + '/../test_helper'

class RubricCriteriaTest < ActiveSupport::TestCase
#  fixtures :assignments, :rubric_criteria
  
  #Test that Criteria with no names are not valid
  def test_no_name_attr
    no_criteria_name = create_no_attr(:rubric_criterion_name)
    assert !no_criteria_name.valid?
  end
  
  # Test to make sure that Criteria have unique names within the scope of a
  # single assignment
  def test_unique_name
    # First, I assume there's a fixture generating a RubricCriterion with
    # the rubric_criteiron_name "Algorithm Design"
    original = RubricCriterion.find_by_rubric_criterion_name("Algorithm Design")
    assert_not_nil original, "Expected to have a RubricCriterion with the name Algorithm Design in the fixtures"
      
    taken_name = create_no_attr(nil)
    taken_name.rubric_criterion_name = "Algorithm Design"
    taken_name.assignment = original.assignment
    assert !taken_name.valid?
    
  end
  
  # Test to make sure that Criteria can have the same names if they belong to
  # different Assignments
  def test_same_name_for_different_assignments
    # First, I assume there's a fixture generating a RubricCriterion with
    # the rubric_criteiron_name "Algorithm Design"
    original = RubricCriterion.find_by_rubric_criterion_name("Algorithm Design")
    assert_not_nil original, "Expected to have a RubricCriterion with the name Algorithm Design in the fixtures"
    
    taken_name = create_no_attr(nil)
    taken_name.rubric_criterion_name = "Algorithm Design"
    
    assignment = Assignment.find_by_name("Captain Sparrow")
    assert_not_nil assignment, "Expected to have an Assignment with the name Captain Sparrow in the fixtures"
    
    taken_name.assignment = assignment
    assert taken_name.valid?  
  end
  
  #Test that Criteria unassigned to Assignment are NOT OK
  def test_no_assignment_id
    no_assignment_id = create_no_attr(:assignment_id)
    assert !no_assignment_id.valid?
  end
  
  #Test that Criteria without weight are NOT OK
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
  
  #Weights are restricted to a decimal value greater than 0
  def test_bad_weight_range
    weight_range = create_no_attr(nil)
    weight_range.weight = 'string'
    assert !weight_range.valid?
    
    weight_range.weight = -0.1
    assert !weight_range.valid?
    
    weight_range.weight = 0.0
    assert !weight_range.valid?
    
    weight_range.weight = 100.0
    assert weight_range.valid?
    
    weight_range.weight = 0.5
    assert weight_range.valid?
    
  end
    
  # Helper method for test_validate_presence_of to create a criterion without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_rubric_criteria = { 
      :rubric_criterion_name => 'somecriteria',
      :assignment_id => Assignment.find(:first).id, 
      :weight => 0.25,
      :level_0_name => 'Horrible',
      :level_1_name => 'Poor',
      :level_2_name => 'Satisfactory',
      :level_3_name => 'Good',
      :level_4_name => 'Excellent'
    }
    
    new_rubric_criteria.delete(attr) if attr
    RubricCriterion.new(new_rubric_criteria)
  end

end

