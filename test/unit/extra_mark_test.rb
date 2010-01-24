require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class ExtraMarkTest < ActiveSupport::TestCase
  fixtures :all
  should_belong_to :result
  should_validate_presence_of :result_id
end
