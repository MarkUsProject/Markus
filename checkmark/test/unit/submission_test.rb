require File.dirname(__FILE__) + '/../test_helper'

class SubmissionTest < ActiveSupport::TestCase
  
  fixtures  :submissions
  
  # Create a separate directory for testing submissions
  SUBMISSIONS_TEST_PATH = File.join(SUBMISSIONS_PATH, "test")
  
  def teardown
    #FileUtils.remove_dir(SUBMISSIONS_TEST_PATH, true)
  end
  
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
  # directly from fixtures (e.g. not "submissions(:studentsub))" to get 
  # specific subclass of Submission (either user or group submission)
  # Append SUBMISSIONS_TEST_PATH when testing submit
  
  # test if correct path is given for individual assignments
  def test_indiv_submit_dir
    owner = users(:student2)
    assignment = assignments(:a3)
    subpath = File.join(SUBMISSIONS_TEST_PATH, assignment.name, owner.user_name)
    
    subm = assignment.submission_by(owner)
    assert_equal subpath, subm.submit_dir(SUBMISSIONS_TEST_PATH)
  end
  
  # test if correct path is given for group assignments
  def test_group_submit_dir
    owner = users(:student5)
    user = users(:student1)
    assignment = assignments(:a2)
    subpath = File.join(SUBMISSIONS_TEST_PATH, assignment.name, owner.user_name)
    
    subm = assignment.submission_by(user)
    assert_equal subpath, subm.submit_dir(SUBMISSIONS_TEST_PATH)
  end
  
  # Test submission for an individual assignment
  def test_indiv_submit
    user = users(:student2)
    subm = assignments(:a3).submission_by(user)
    assert subm.is_a?(UserSubmission) # make sure correct instance is given
    
    sub_time = Time.now
    tempfile = to_upload_file("Shapes.java", "this is content")
    filename = tempfile.original_filename
    assert_equal 2, subm.submission_files.count  # from test fixtures
    
    # check if file has indeed been copied
    subm.submit(user, tempfile, sub_time, SUBMISSIONS_TEST_PATH)
    file = File.join(subm.submit_dir(SUBMISSIONS_TEST_PATH), filename)
    assert File.exist?(file), file
    
    # check submission file record
    t = subm.last_submission_time_by_filename(filename)
    assert_equal sub_time, t
    
    # test resubmit same file
    new_sub_time = Time.now
    subm.submit(user, tempfile, new_sub_time, SUBMISSIONS_TEST_PATH)
    file = File.join(subm.submit_dir(SUBMISSIONS_TEST_PATH), filename)
    assert File.exist?(file)
    assert_equal 4, subm.submission_files.count  # test fixtures + 2 submissions
    assert_equal new_sub_time, subm.last_submission_time_by_filename(filename)
    backup = File.join(subm.submit_dir(SUBMISSIONS_TEST_PATH), 
      sub_time.strftime("%m-%d-%Y-%H-%M-%S"))
    assert File.exist?(backup), backup  # check if backup has been copied
  end
  
  
  protected
  
  # Wraps a String to an "upload file" that is expected when submitting.
  # "Upload file" is just an StringIO with an original_filename method, 
  # compared to real ActionController::UploadFile used in uploads.
  def to_upload_file(filename, content)
    strfile = StringIO.new(content)

    def strfile.original_filename=(filename)  # instance setter method
      @filename = filename
    end
    
    def strfile.original_filename  # instace setter method
      return @filename
    end
    
    strfile.original_filename = filename
    assert_equal filename, strfile.original_filename
    return strfile
  end
  
end
