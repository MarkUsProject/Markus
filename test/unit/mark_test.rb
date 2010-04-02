require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class MarkTest < ActiveSupport::TestCase
  fixtures :all
  should_belong_to :markable
  should_belong_to :result
  should_validate_presence_of :result_id, :markable_id, :markable_type
  
  should_allow_values_for :mark, 0, 1, 2, 3, 4
  should_not_allow_values_for :mark, -2, -1, 5, 6

  should_allow_values_for :result_id, 1, 2, 3
  should_not_allow_values_for :result_id, -2, -1, 0

  should_allow_values_for :markable_id, 1, 2, 3
  should_not_allow_values_for :markable_id, -2, -1, 0

  should_allow_values_for :markable_type, "RubricCriterion", "FlexibleCriterion"
  should_not_allow_values_for :markable_type, "", nil
  
  should_validate_uniqueness_of :markable_id, :scoped_to => [:result_id, :markable_type]
  
  context "A mark asociated with RubricCriterion" do   
    setup do
      @mark = marks(:mark_1)
    end
       
    should "return the good value" do
      assert_equal(2, @mark.get_mark)
    end
  end
  
  context "A mark asociated with FlexibleCriterion" do   
    setup do
      @mark = marks(:flexible_mark)
    end
       
    should "return the good value" do
      assert_equal(4, @mark.get_mark)
    end
  end
end
