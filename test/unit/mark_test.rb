require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../blueprints/helper'
require 'shoulda'

class MarkTest < ActiveSupport::TestCase
  fixtures :all
  should_belong_to :markable
  should_belong_to :result
  should_validate_presence_of :result_id, :markable_id, :markable_type
  
  should_allow_values_for :result_id, 1, 2, 3
  should_not_allow_values_for :result_id, -2, -1, 0

  should_allow_values_for :markable_id, 1, 2, 3
  should_not_allow_values_for :markable_id, -2, -1, 0

  should_allow_values_for :markable_type, "RubricCriterion", "FlexibleCriterion"
  should_not_allow_values_for :markable_type, "", nil
  
  should_validate_uniqueness_of :markable_id, :scoped_to => [:result_id, :markable_type]
  
  context "A mark asociated with RubricCriterion" do   
    setup do
      @mark = Mark.make(:rubric, :mark => 2)
    end
      
    should "allow valid values" do
      values = [0, 2, 3, 4]
      values.each do |val|
        assert(@mark.update_attributes(:mark => val), val.to_s)  
      end
    end
    
    should "not allow invalid values" do
      values = [-1, 5, -10, 10]
      values.each do |val|
        assert(!@mark.update_attributes(:mark => val), val.to_s)
      end
    end
    
    should "return the good value" do
      assert_equal(2, @mark.get_mark)
    end
  end
  
  context "A mark asociated with FlexibleCriterion" do   
    setup do
      # max of flexible criterion is 10 in blueprint
      @mark = Mark.make(:flexible, :mark => 4)
    end
       
    should "allow valid values" do
      values = [0, 1, 6, 9, 10]
      values.each do |val|
        assert(@mark.update_attributes(:mark => val), val.to_s)  
      end
    end
    
    should "not allow invalid values" do
      values = [-1, -2, -5, 11, 12, 20]
      values.each do |val|
        assert(!@mark.update_attributes(:mark => val), val.to_s)
      end
    end
    
    should "return the good value" do
      assert_equal(4, @mark.get_mark)
    end
  end
end
