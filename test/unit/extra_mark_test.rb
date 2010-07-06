require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class ExtraMarkTest < ActiveSupport::TestCase
  fixtures :all
  should belong_to :result
  should validate_presence_of :result_id
end
