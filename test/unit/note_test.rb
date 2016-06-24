# test using MACHINIST

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class NoteTest < ActiveSupport::TestCase
  should validate_presence_of :notes_message
  should validate_presence_of :creator_id
  should validate_presence_of :noteable
  should belong_to :noteable
  should belong_to :user

  context 'noteables_exist?'  do

    should 'return false when no noteables exist' do
      Assignment.destroy_all
      Grouping.destroy_all
      Student.destroy_all
      assert !Note.noteables_exist?
    end

    {Grouping: lambda {Grouping.make}, Student: lambda {Student.make} ,Assignment: lambda {Assignment.make} }.each_pair do |type, noteable|
      context "when #{type.to_s} exist" do
        setup do
          @noteable = noteable.call()
        end
        should  'return true' do
          assert Note.noteables_exist?
        end
      end
    end
  end

end
