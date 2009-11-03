require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class FlexibleCriterionTest < ActiveSupport::TestCase
  should_belong_to :assignment
  
  # Not yet functional
  # should_have_many :marks
  
  should_validate_presence_of :flexible_criterion_name, :assignment_id, :max
  
  should_validate_uniqueness_of :flexible_criterion_name, :scoped_to => :assignment_id, :message => 'is already taken'
  should_validate_numericality_of :assignment_id, :message => "can only be whole number greater than 0"
  should_validate_numericality_of :max, :message => "must be a number greater than 0.0"

  should_allow_values_for :max, 0.1, 1.0, 100.0
  should_not_allow_values_for :max, 0.0, -1.0, -100.0

  should_allow_values_for :assignment_id, 1, 2, 100
  should_not_allow_values_for :assignment_id, 0, -1, -100
  
end
