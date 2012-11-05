# test using MACHINIST

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestSupportFileTest < ActiveSupport::TestCase
  should belong_to :assignment

  context "A valid test support file" do

    should "return true when a valid file is created" do
      @supportfile = TestSupportFile.make(:file_name => 'input.txt', :description => 'This is an input file')
      assert @supportfile.valid?
    end
    
    should "return true when the description is empty" do
      @supportfile = TestSupportFile.make(:file_name => 'actual_output.txt', :description => '')
      assert @supportfile.valid?
    end

  end

  context "An invalid test support file" do
    
    setup do
      @validsupportfile = TestSupportFile.make(:file_name => 'valid', :description => 'This is a valid support file')
      @invalidsupportfile = TestSupportFile.make(:file_name => 'invalid', :description => 'This is an invalid support file')
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
      @invalidsupportfile.file_name = 'valid'
      assert !@invalidsupportfile.valid?, "support file expected to be invalid when the file name already exists"
    end

  end

end
