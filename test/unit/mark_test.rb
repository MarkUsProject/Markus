require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class MarkTest < ActiveSupport::TestCase

  should belong_to :markable
  should belong_to :result
  should validate_presence_of :result_id
  should validate_presence_of :markable_id
  should validate_presence_of :markable_type

  should allow_value(1).for(:result_id)
  should allow_value(2).for(:result_id)
  should allow_value(3).for(:result_id)
  should_not allow_value(-2).for(:result_id)
  should_not allow_value(-1).for(:result_id)
  should_not allow_value(0).for(:result_id)

  should allow_value(1).for(:markable_id)
  should allow_value(2).for(:markable_id)
  should allow_value(3).for(:markable_id)
  should_not allow_value(-2).for(:markable_id)
  should_not allow_value(-1).for(:markable_id)
  should_not allow_value(0).for(:markable_id)

  should allow_value('RubricCriterion').for(:markable_type)
  should allow_value('FlexibleCriterion').for(:markable_type)
  should_not allow_value('').for(:markable_type)
  should_not allow_value(nil).for(:markable_type)

  context 'A good Mark model' do
    setup do
      Mark.make
    end
    should validate_uniqueness_of(:markable_id).scoped_to([:result_id, :markable_type])
  end

  context 'A mark asociated with RubricCriterion' do
    setup do
      @mark = Mark.make(:rubric, :mark => 2)
    end

    should 'allow valid values' do
      values = [0, 2, 3, 4]
      values.each do |val|
        assert(@mark.update_attributes(:mark => val), val.to_s)
      end
    end

    should 'not allow invalid values' do
      values = [-1, 5, -10, 10]
      values.each do |val|
        assert(!@mark.update_attributes(:mark => val), val.to_s)
      end
    end

    should 'return the good value' do
      assert_equal(2, @mark.get_mark)
    end
  end

  context 'A mark asociated with FlexibleCriterion' do
    setup do
      # max of flexible criterion is 10 in blueprint
      @mark = Mark.make(:flexible, :mark => 4)
    end

    should 'allow valid values' do
      values = [0, 1, 6, 9, 10]
      values.each do |val|
        assert(@mark.update_attributes(:mark => val), val.to_s)
      end
    end

    should 'not allow invalid values' do
      values = [-1, -2, -5, 11, 12, 20]
      values.each do |val|
        assert(!@mark.update_attributes(:mark => val), val.to_s)
      end
    end

    should 'return the good value' do
      assert_equal(4, @mark.get_mark)
    end
  end
end
