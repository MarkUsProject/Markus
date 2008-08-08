require File.dirname(__FILE__) + '/../test_helper'

class AssignmentTest < Test::Unit::TestCase
  
  fixtures :assignments
  
  def setup
    @assign = Assignment.new({:name => 'A1'})
  end
  
  # Tests if group limit cannot be assigned a value < 1
  def test_numericality_group_min
    @assign.group_min = 0
    assert !@assign.valid?
    @assign.group_min = -5
    assert !@assign.valid?
    assert !@assign.save
  end
end
