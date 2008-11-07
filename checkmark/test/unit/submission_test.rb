require File.dirname(__FILE__) + '/../test_helper'

class SubmissionTest < ActiveSupport::TestCase
  
  fixtures  :submissions
  
  # Create a separate directory for testing submissions
  SUBMISSIONS_TEST_PATH = File.join(SUBMISSIONS_PATH, "test")
  
  # Query function tests --------------------------------------------------
  
  def test_submitted_filenames
    student2_subs = submissions(:student2a3sub)
    files = student2_subs.submitted_filenames
    
    filenames = files.map { |sf| sf.filename  }
    assert 2, files.length
    assert filenames.include?("test1.txt")
    assert filenames.include?("test2.txt")
  end
  
  def test_submitted_filenames_group
    group4_subs = submissions(:group4a2sub)
    files = group4_subs.submitted_filenames
    
    filenames = files.map { |sf| sf.filename  }
    assert 2, files.length
    assert filenames.include?("test3.txt") # submitted by student 5
    assert filenames.include?("test4.txt") # submitted by student 1
  end
  
  def test_last_submission_time
    student2_subs = submissions(:student2a3sub)
    student2_subs.last_submission_time
  end
  
  # File upload tests  -----------------------------------------------------
  # Need to get submission instance from Assigment.submitted_by and not 
  # directly from fixtures (e.g. not "submissions(:studentsub))"
  # Append SUBMISSIONS_TEST_PATH when testing submit
  
  def test_indiv_submit
    user = users(:student2)
    subm = assignments(:a3).submission_by(user)
    assert student2_subs.is_a?(UserSubmission)  # make sure owner is correct
    
    t = Time.now
    subm.submit(user, "/files/Shapes.java", t, SUBMISSIONS_TEST_PATH)
  end
  
end
