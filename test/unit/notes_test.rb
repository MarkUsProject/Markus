require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class NotesTest < ActiveSupport::TestCase
  should_validate_presence_of :notes_message, :creator_id, :noteable
  should_belong_to :noteable, :user
  
end
