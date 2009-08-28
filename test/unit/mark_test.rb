require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class MarkTest < ActiveSupport::TestCase
  fixtures :rubric_criteria, :results, :marks
  should_belong_to :rubric_criterion
  should_belong_to :result
  should_validate_presence_of :result_id, :rubric_criterion_id

#  def test_get_mark
#     mark = marks(:mark_2)
#     assert_equal(6, mark.get_mark)
#  end

end
