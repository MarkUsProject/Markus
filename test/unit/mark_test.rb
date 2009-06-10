require File.dirname(__FILE__) + '/../test_helper'

class MarkTest < ActiveSupport::TestCase
  fixtures :rubric_criterias, :results
  
  def test_create_mark
    mark = Mark.new({:result => results(:r1), :mark => 4, :rubric_criteria => rubric_criterias(:c1)})
    assert mark.valid?
  end

  def test_create_invalid_mark
    mark = Mark.new({:result => results(:r1), :mark => 7, :rubric_criteria => rubric_criterias(:c2)})
    assert !mark.valid?, "Mark cannot be greater than 4"
  end

  def test_create_invalid_mark2
    mark = Mark.new({:result => results(:r1), :mark => -5, :rubric_criteria => rubric_criterias(:c2)})
    assert !mark.valid?, "Mark cannot be less than 0"
  end

end
