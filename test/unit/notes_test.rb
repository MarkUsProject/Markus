require 'test_helper'
require 'shoulda'

class NotesTest < ActiveSupport::TestCase
  should_validate_presence_of :notes_message, :grouping_id, :creator_id, :type_association
  should_belong_to :grouping, :user
  
end
