require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class ResultTest < ActiveSupport::TestCase
  # set_fixture_class is required here, since we don't use Rails'
  # standard pluralization for rubric criteria
  set_fixture_class :rubric_criteria => RubricCriterion 
  fixtures :assignments, :rubric_criteria,  :submissions, :marks, :results, :extra_marks

  should_have_many :marks
  should_have_many :extra_marks
  should_validate_presence_of :marking_state

  def test_get_subtotal
    result = results(:result_1)
    assert_equal(6, result.get_subtotal, "Subtotal should be equal to 10")
  end
end
