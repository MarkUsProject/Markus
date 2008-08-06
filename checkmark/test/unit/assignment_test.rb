require File.dirname(__FILE__) + '/../test_helper'

class AssignmentTest < Test::Unit::TestCase
  
  fixtures :assignments
  
  def setup
    @assign = Assignment.new({:name => 'A1'})
  end
  
  # Tests if group limit cannot be assigned a value < 1
  def test_numericality_group_limit
    @assign.group_limit = 0
    assert !@assign.valid?
    @assign.group_limit = -5
    assert !@assign.valid?
    assert !@assign.save
  end
end
