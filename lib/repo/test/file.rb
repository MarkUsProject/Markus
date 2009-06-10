require 'test/unit'
require '../repository'

class File_Test < Test::Unit::TestCase
   
  # test various constructors of File class
  def test_create_file
    file1 = Repository::File.new
    atthash = { :name => "",
                :revision => "",
                :path => "/bla",
                :last_modified_by => "userid/cdfuserid",
                :last_modified_date => "timestamp",
                :mime_type => "something",
                :file_content => "content" }
    file2 = Repository::File.new(atthash)
    
    assert_not_nil(file1, "Unable to create a File instance with empty parameters")
    assert_not_nil(file2, "Unable to create a File instance with hashed parameters")
  end
  
  # test if retrieving and setting content of a file works
  def test_get_set_file_content
    atthash = { :name => "new_filename",
                :revision => "1235B",
                :path => "/bla",
                :last_modified_by => "cdfuserid",
                :last_modified_date => "timestamp",
                :mime_type => "image/jpeg",
                :file_content => "content" }
    file1 = Repository::File.new(atthash)
    mycont = "string"
    file1.file_content = mycont
    file_content = file1.file_content
    assert_equal(mycont, file_content, "Failed setting and getting file contents")    
  end
  
  
end
