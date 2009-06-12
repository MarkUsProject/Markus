require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class ExtraMarkTest < Test::Unit::TestCase
  should_belong_to :result
  should_require_attributes :result_id
end
