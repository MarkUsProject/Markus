require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class MarkTest < ActiveSupport::TestCase
  fixtures :rubric_criteria, :results
  should_belong_to :rubric_criterion
  should_belong_to :result
  should_validate_presence_of :result_id, :rubric_criterion_id
  
  def test_create_mark
    mark = Mark.new({:result => results(:r1), :mark => 4,:rubric_criterion => rubric_criteria(:c1)})
    assert mark.valid?
  end

  def test_create_invalid_mark
    mark = Mark.new({:result => results(:r1), :mark => 7, :rubric_criterion => rubric_criteria(:c2)})
    assert !mark.valid?, "Mark cannot be greater than 4"
  end

  def test_create_invalid_mark2
    mark = Mark.new({:result => results(:r1), :mark => -5, :rubric_criterion => rubric_criteria(:c2)})
    assert !mark.valid?, "Mark cannot be less than 0"
  end

end
