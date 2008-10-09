require File.dirname(__FILE__) + '/../test_helper'

class SubmissionTest < ActiveSupport::TestCase
  
  fixtures  :submissions
  
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
  
end
