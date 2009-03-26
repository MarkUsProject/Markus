require File.dirname(__FILE__) + '/../test_helper'

class ResultTest < ActiveSupport::TestCase
  fixtures :assignments, :rubric_criterias,  :submissions, :results, :marks, :extra_marks

  # Replace this with your real tests.
  def test_calculate_total
    result = results(:r1)
    total = result.calculate_total
    assert_equal 30, total
    bonus_marks = result.get_bonus_marks
    assert_equal 5, bonus_marks
    deductions = result.get_deductions
    assert_equal deductions, -9
  end

end
