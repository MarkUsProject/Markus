# test using MACHINIST

require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__), '/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class NoteTest < ActiveSupport::TestCase
  should_validate_presence_of :notes_message, :creator_id, :noteable
  should_belong_to :noteable, :user

  context "noteables_exist?"  do
    setup do
      clear_fixtures
    end

    should "return false when no noteables exist" do
      assert !Note.noteables_exist?
    end

    {:Grouping => lambda {Grouping.make}, :Student => lambda {Student.make} ,:Assignment => lambda {Assignment.make} }.each_pair do |type, noteable|
      context "when #{type.to_s} exist" do
        setup do
          @noteable = noteable.call()
        end
        should  "return true" do
          assert Note.noteables_exist?
        end
      end
    end
  end
  
end
