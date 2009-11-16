require 'test_helper'
require 'shoulda'

class NotesTest < ActiveSupport::TestCase
  should_validate_presence_of :message, :grouping_id, :creator_id, :type
  should_belong_to :grouping, :user
  
end
