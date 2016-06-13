# test using MACHINIST

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestSupportFileTest < ActiveSupport::TestCase
  should belong_to :assignment
  
  should validate_presence_of :assignment
  should validate_presence_of :file_name
  
  # create
  context "A valid test support file" do

    should "return true when a valid file is created" do
      @supportfile = TestSupportFile.make(file_name: 'input.txt', description: 'This is an input file')
      assert @supportfile.valid?
      assert @supportfile.save
    end
    
    should "return true when a valid file is created even if the description is empty" do
      @supportfile = TestSupportFile.make(file_name: 'actual_output.txt', description: '')
      assert @supportfile.valid?
      assert @supportfile.save
    end

  end

  # update
  context "An invalid test support file" do
    
    setup do
      @validsupportfile = TestSupportFile.make(file_name: 'valid', description: 'This is a valid support file')
      @invalidsupportfile = TestSupportFile.make(file_name: 'invalid', description: 'This is an invalid support file')
    end
    
    should "return false when the file_name is blank" do
      @invalidsupportfile.file_name = '   '
      assert !@invalidsupportfile.valid?, "support file expected to be invalid when the file name is blank"
    end

    should "return false when the description is nil" do
      @invalidsupportfile.description = nil
      assert !@invalidsupportfile.valid?, "support file expected to be invalid when the description is nil"
    end

    should "return false when the file_name already exists" do
      @validsupportfile.assignment_id = 1
      @invalidsupportfile.assignment_id = 1
      @invalidsupportfile.file_name = 'valid'
      assert !@invalidsupportfile.valid?, "support file expected to be invalid when the file name already exists in the same assignment"
    end

  end
  
  # delete
  context "MarkUs" do
    
    should "be able to delete a test support file" do
      @supportfile = TestSupportFile.make(file_name: 'input.txt', description: 'This is an input file')
      assert @supportfile.valid?
      assert @supportfile.destroy
    end
    
  end

end
