require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class MarkTest < ActiveSupport::TestCase
  fixtures :rubric_criteria, :results
  should_belong_to :rubric_criterion
  should_belong_to :result
  should_validate_presence_of :result_id, :rubric_criterion_id
  
end
