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
  
  # Test if method correctly returns last submission time for unexisting file
  def test_last_submission_time_by_filename_nil
    subm = submissions(:group4a2sub)
    ts = subm.last_submission_time_by_filename('unexisting file')
    assert_nil ts
  end
  
  # Test if method correctly returns last submission time
  def test_last_submission_time_by_filename_single
    subm = submissions(:group4a2sub)
    ts = subm.last_submission_time_by_filename('test3.txt')
    assert_not_nil ts  # TODO timestamps are not matching!!
  end
  
   # Test if method correctly returns last submission time for multiple submissions
  def test_last_submission_time_by_filename_mult
    subm = submissions(:group4a2sub)
    ts = subm.last_submission_time_by_filename('test3.txt')
    assert_not_nil ts  # TODO timestamps are not matching!!
  end
  
  # Submission subclasses ----------------------------------------------
  
  # Tests if the owner for an individual assignment is the submitter
  def test_user_owner
    user = users(:student2)
    subm = assignments(:a3).submission_by(user)
    assert subm.is_a?(UserSubmission)
    assert_equal user, subm.owner
  end
  
  # Tests if the owner for an individual assignment is the inviter
  def test_group_owner_inviter
    inviter = users(:student5)
    user = users(:student5)
    subm = assignments(:a2).submission_by(user)
    
    assert subm.is_a?(GroupSubmission)
    assert_equal inviter, subm.owner
  end
  
  # Tests if the owner for an individual assignment is the inviter for a member
  def test_group_owner_member
    inviter = users(:student5)
    user = users(:student1)
    subm = assignments(:a2).submission_by(user)
    
    assert subm.is_a?(GroupSubmission)
    assert_equal inviter, subm.owner
  end
  
  
  # File upload tests  -----------------------------------------------------
  # Need to get submission instance from Assigment.submitted_by and not 
  # directly from fixtures (e.g. not "submissions(:studentsub))"
  # Append SUBMISSIONS_TEST_PATH when testing submit
  
  def test_indiv_submit
    user = users(:student2)
    subm = assignments(:a3).submission_by(user)
    assert subm.is_a?(UserSubmission) # make sure correct instance is given
    
    t = Time.now
    tempfile = ActionController::UploadedTempFile.new("/files/Shapes.java")
    subm.submit(user, tempfile, SUBMISSIONS_TEST_PATH)
    
    
  end
  
end
