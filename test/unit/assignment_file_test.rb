require File.join(File.dirname(__FILE__), '..', 'test_helper')

class AssignmentFileTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  fixtures :all
  def test_presence_of_filename
    assignmentfile = AssignmentFile.new
    assignmentfile.assignment_id = 1
    assert !assignmentfile.save
  end

 def test_uniqueness_of_filename
    assignmentfile = AssignmentFile.new
    assignmentfile.assignment_id = 1
    assignmentfile.filename = "test"
    assert assignmentfile.save

    assignmentfile2 = AssignmentFile.new
    assignmentfile2.assignment_id = 1
    assignmentfile2.filename = "test"
    assert !assignmentfile2.save
 end
 def test_format_of_filename
    assignmentfile = AssignmentFile.new
    assignmentfile.assignment_id = 1
    assignmentfile.filename = "test*"
    assert !assignmentfile.save

 end
end
