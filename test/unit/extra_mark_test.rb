require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require 'shoulda'

class ExtraMarkTest < ActiveSupport::TestCase
  should belong_to :result
  should validate_presence_of :result_id
end
