require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'
class AssignmentFileTest < ActiveSupport::TestCase
  context "A good assignmentFile model" do
    setup do
      AssignmentFile.make
    end
    should "have an unique file name" do
      assert validate_uniqueness_of(:filename).scoped_to(:assignment_id)
    end
    should belong_to :assignment
    should validate_presence_of :filename
    should allow_value('est.java').for(:filename)
    should_not allow_value('"éàç_(*8').for(:filename)
  end
end
