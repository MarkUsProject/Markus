# test using MACHINIST

require File.join(File.dirname(__FILE__),'..', 'test_helper')
require File.join(File.dirname(__FILE__),'..', 'blueprints', 'helper')
require 'shoulda'

class TestFileTest < ActiveSupport::TestCase
  should validate_presence_of :filename
  should belong_to :assignment

  context 'A valid test file' do

    should 'return true when a valid build.xml file is created' do
      @buildfile = TestFile.make(:filetype => 'build.xml', :filename => 'build.xml')
      assert @buildfile.valid?
    end

    should 'return true when a valid build.properties file is created' do
      @buildproperties = TestFile.make(:filetype => 'build.properties', :filename => 'build.properties')
      assert @buildproperties.valid?
    end

    should 'return true when a valid test file is created' do
      @testfile = TestFile.make(:filetype => 'test', :filename => 'ValidTestFile')
      assert @testfile.valid?
    end

    should 'return true when a valid lib file is created' do
      @libfile = TestFile.make(:filetype => 'lib', :filename => 'ValidLibraryFile')
      assert @libfile.valid?
    end

    should 'return true when a valid parse file is created' do
      @parsefile = TestFile.make(:filetype => 'parse', :filename => 'ValidParseFile')
      assert @parsefile.valid?
    end
  end

  context 'An invalid ant file' do
    setup do
      @buildfile = TestFile.make(:filetype => 'build.xml', :filename => 'build.xml')
      @buildproperties = TestFile.make(:filetype => 'build.properties', :filename => 'build.properties')
    end

    should 'return false when build.xml file is not named build.xml' do
      @buildfile.filename = 'anotherbuildfile'
      assert !@buildfile.valid?, 'build file expected to be invalid when not named build.xml'
    end

    should 'return false when build.properties file is not named build.properties' do
      @buildproperties.filename = 'anotherpropfile'
      assert !@buildproperties.valid?, 'properties file expected to be invalid when not named build.properties'
    end
  end

  context 'An invalid test file' do
    setup do
      @validtestfile = TestFile.make(:filetype => 'test', :filename => 'SomeValidTestFile')
      @invalidtestfile = TestFile.make(:filetype => 'test', :filename => 'TestFile')
    end

    should 'return false when a test file is created with a blank filename' do
      @invalidtestfile.filename = ''
      assert !@invalidtestfile.valid?, 'test file expected to be invalid when filename is blank'
    end

    should 'return false when the test filename already exists' do
      @invalidtestfile.filename = 'SomeValidTestFile'
      assert !@invalidtestfile.valid?, 'test file expected to be invalid when filename already exists'
    end

    should 'return false when test file is named build.xml' do
      @invalidtestfile.filename = 'build.xml'
      assert !@invalidtestfile.valid?, 'test file expected to be invalid when filename is build.xml or build.properties'
    end

    should 'return false when test file is named build.properties' do
      @invalidtestfile.filename = 'build.properties'
      assert !@invalidtestfile.valid?, 'test file expected to be invalid when filename is build.xml or build.properties'
    end
  end

  context 'An invalid library file' do
    setup do
      @validlibfile = TestFile.make(:filetype => 'lib', :filename => 'SomeValidLibFile')
      @invalidlibfile = TestFile.make(:filetype => 'lib', :filename => 'LibFile')
    end

    should 'return false when a library file is created with a blank filename' do
      @invalidlibfile.filename = ''
      assert !@invalidlibfile.valid?, 'library file expected to be invalid when filename is blank'
    end

    should 'return false when the library filename already exists' do
      @invalidlibfile.filename = 'SomeValidLibFile'
      assert !@invalidlibfile.valid?, 'lib file expected to be invalid when filename already exists'
    end

    should 'return false when library file is named build.xml' do
      @invalidlibfile.filename = 'build.xml'
      assert !@invalidlibfile.valid?, 'lib file expected to be invalid when filename is build.xml or build.properties'
    end

    should 'return false when library file is named build.properties' do
      @invalidlibfile.filename = 'build.properties'
      assert !@invalidlibfile.valid?, 'lib file expected to be invalid when filename is build.xml or build.properties'
    end
  end

  context 'An invalid parser file' do
    setup do
      @validparsefile = TestFile.make(:filetype => 'parse', :filename => 'SomeValidParseFile')
      @invalidparsefile = TestFile.make(:filetype => 'parse', :filename => 'ParseFile')
    end

    should 'return false when a parser file is created with a blank filename' do
      @invalidparsefile.filename = ''
      assert !@invalidparsefile.valid?, 'parser file expected to be invalid when filename is blank'
    end

    should 'return false when the parser filename already exists' do
      @invalidparsefile.filename = 'SomeValidParseFile'
      assert !@invalidparsefile.valid?, 'parser file expected to be invalid when filename already exists'
    end

    should 'return false when parser file is named build.xml' do
      @invalidparsefile.filename = 'build.xml'
      assert !@invalidparsefile.valid?, 'parser file expected to be invalid when filename is build.xml or build.properties'
    end

    should 'return false when parser file is named build.properties' do
      @invalidparsefile.filename = 'build.properties'
      assert !@invalidparsefile.valid?, 'parser file expected to be invalid when filename is build.xml or build.properties'
    end
  end
end
