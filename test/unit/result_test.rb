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
  
  def test_unreleased_true
    result = results(:result_4)
    result.unrelease_results
    assert(!result.released_to_students, "result should be unreleased")
  end

  def test_unreleased
    result = results(:result_4)
    result.unrelease_results
    assert_equal('partial', result.marking_state, "makring state should
    be partial")
  end

  def test_mark_as_partial
    result = results(:result_3)
    result.mark_as_partial
    assert_equal('partial', result.marking_state, "marking state should
    e partial")
  end

  def test_mark_as_partial2
    result = results(:result_4)
    result.mark_as_partial
    assert_equal('complete', result.marking_state, "marking state should
    e partial")
  end

end
