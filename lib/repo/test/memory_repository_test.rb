require File.join(File.dirname(__FILE__),'/../memory_repository')
require 'test/unit'
require 'rubygems'
require 'ruby-debug'
require 'shoulda'   # load Thoughtbot Shoulda (used as testing framework)
require 'time'
include Repository # bring Repository module into current namespace

class MemoryRepositoryTest < Test::Unit::TestCase
  
  RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__),"/input_files"))
  TEST_USER = "testuser"
  REPO_LOCATION = File.expand_path(File.join(File.dirname(__FILE__),'memory_repo1'))
  ANOTHER_REPO_LOCATION = File.expand_path(File.join(File.dirname(__FILE__),'memory_repo2'))
  # following constant not used as of now
  TEST_REPO_CONTENT = File.expand_path(File.join(File.dirname(__FILE__),'/../memory_repository.yml'))
  
  context "MemoryRepository class" do
    
    teardown do
      MemoryRepository.purge_all()
    end
    
    should "be able to create a new Memory repository" do
      repo = MemoryRepository.create(REPO_LOCATION)
      assert_not_nil(repo, "Could not create Repository")
      assert_instance_of(Repository::MemoryRepository, repo, "Repository is of wrong type")
      # and create another one :-)
      repo2 = MemoryRepository.create(ANOTHER_REPO_LOCATION)
      assert_not_nil(repo2, "Could not create Repository")
      assert_instance_of(Repository::MemoryRepository, repo2, "Repository is of wrong type")
    end
    
    should "be able to open an existing Memory repository" do
      MemoryRepository.create(REPO_LOCATION)
      MemoryRepository.create(ANOTHER_REPO_LOCATION) # creat another one
      repo = MemoryRepository.open(REPO_LOCATION) # open repository created first
      assert_not_nil(repo, "Cannot open memory repository")
      assert_instance_of(Repository::MemoryRepository, repo, "Repository is of wrong type")
    end
    
    should "know if a memory repository exists at some place" do
      MemoryRepository.create(REPO_LOCATION)
      MemoryRepository.create(ANOTHER_REPO_LOCATION) # creat another one
      assert_equal(MemoryRepository.repository_exists?(REPO_LOCATION), true, "A memory repository should exist at: '"+REPO_LOCATION+"'")
      assert_equal(MemoryRepository.repository_exists?(ANOTHER_REPO_LOCATION), true, "A memory repository should exist at: '"+ANOTHER_REPO_LOCATION+"'")
    end
  end
  
  context "A MemoryRepository instance" do
    
    # setup and teardown for the current context
    
    # creates a new memory repository with content
    # specified in TEST_REPO_CONTENT
    setup do
      MemoryRepository.create(REPO_LOCATION) # create repository first
      @repo = MemoryRepository.new(REPO_LOCATION)
    end
    
    # destroy all repositories created
    teardown do
      MemoryRepository.purge_all()
    end
    
    # beginning of tests
   
    should "have been instanciated and ready to use" do
      assert_not_nil(@repo, "Could not create/open Repository")
    end
    
    should "provide a transaction" do
      transaction = @repo.get_transaction(TEST_USER)
      assert_not_nil(transaction, "Could not retrieve transaction")
      assert_instance_of(Repository::Transaction, transaction, "Transaction is not of correct type!")
    end
    
    should "give the latest revision" do
      revision = @repo.get_latest_revision()
      assert_not_nil(revision, "Could not retrieve latest revision")
      assert_instance_of(Repository::MemoryRevision, revision, "Revision is of wrong type!")
    end
    
    should "be able to retrieve a revision given a valid revision as integer number" do
      r = @repo.get_latest_revision()
      assert_not_nil(r, "Could not retrieve latest revision")
      rev_int = r.revision_number
      new_revision = @repo.get_revision(rev_int)
      assert_instance_of(Repository::MemoryRevision, new_revision, "Revision not of class MemoryRevision")
      assert_equal(new_revision.revision_number, rev_int, "Revision numbers (int values) should be equal")
    end
    
    should "raise a RevisionDoesNotExist exception" do
      r = @repo.get_latest_revision()
      assert_not_nil(r, "Could not retrieve latest revision")
      revision_non_existent = r.revision_number + 3
      assert_raise(RevisionDoesNotExist) do
        @repo.get_revision(revision_non_existent) # raises exception
      end
    end
    
    add_file_test = "add a new file to an empty repository"
    should(add_file_test) do
      rev_num = @repo.get_latest_revision().revision_number
      txn = @repo.get_transaction(TEST_USER)      
      filename = "MyClass.java"
      file_contents = File.read(RESOURCE_DIR+"/"+filename)
      txn.add("/"+filename, file_contents)
      latest_revision = @repo.get_latest_revision().revision_number
      assert_equal(rev_num, latest_revision, "Revision # should be the same!")
      @repo.commit(txn) # commit transaction
      latest_revision = @repo.get_latest_revision().revision_number
      
      assert_not_equal(rev_num, latest_revision, "Revision # has not changed!")
      
      # look if new file is available
      rev = @repo.get_latest_revision()
      files = rev.files_at_path("/")
      assert_not_nil(files[filename], "Could not find file '"+filename+"'")
      # test download_as_string
      assert_equal(@repo.download_as_string(files[filename]), file_contents, "Mismatching content")
    end
    
    should "delete a commited file from repository" do
      # this is how one would call another shoulda test in test :-)
      add_file_test.intern() # call add_file_test to make sure it works, not sure if that's useful
      # add MyClass.java to repo
      filename = "MyClass.java"
      add_file_helper(@repo, "/"+filename)
      txn = @repo.get_transaction(TEST_USER)
      txn.remove("/"+filename, @repo.get_latest_revision().revision_number)
      @repo.commit(txn)
      
      # filename should not be available in repo now
      rev = @repo.get_latest_revision()
      files = rev.files_at_path("/")
      assert_nil(files, "File '"+filename+"' should have been removed!")
    end
    
    should "be able to add multiple files using a single transaction" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      old_revision = @repo.get_latest_revision()
      add_some_files_helper(@repo, files_to_add)
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::MemoryRevision, old_revision, "Should be of type MemoryRevision")
      assert_instance_of(Repository::MemoryRevision, new_revision, "Should be of type MemoryRevision")
      assert_equal(old_revision.revision_number + 1, new_revision.revision_number, "Revision number should have been increased by 1")
      # repository should know of the added files, now
      files = new_revision.files_at_path("/")
      files_to_add.each do |file|
        assert_not_nil(files[file], "File '"+file+"' not found in repository")
        content = File.read(RESOURCE_DIR+"/"+file)
        # test stringify_files also
        assert_equal(content, @repo.stringify_files(files[file]))
      end
    end
    
    should "be able to add, remove using a single transaction" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      old_revision = @repo.get_latest_revision()
      # add one more file
      filename = "ruby_file.rb"
      txn = @repo.get_transaction(TEST_USER)
      file_contents = File.read(RESOURCE_DIR+"/"+filename)
      txn.add("/"+filename, file_contents)
      # remove a file
      txn.remove("/test.xml", @repo.get_latest_revision().revision_number) # remove a file previously existent in current rev.
      @repo.commit(txn)
      
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::MemoryRevision, old_revision, "Should be of type MemoryRevision")
      assert_instance_of(Repository::MemoryRevision, new_revision, "Should be of type MemoryRevision")
      assert_equal(old_revision.revision_number + 1, new_revision.revision_number, "Revision number should have been increased by 1")
      # test repository on its correct content
      files = new_revision.files_at_path("/")
      files_to_add << filename # push filename to files_to_add
      files_to_add.each do |file|
        if file != "test.xml"
          assert_not_nil(files[file], "File '"+file+"' not found in repository")
          content = File.read(RESOURCE_DIR+"/"+file)
          # test stringify_files also
          assert_equal(content, @repo.stringify_files(files[file]))
        end
      end
    end
    
    should "be able to get a revision by timestamp" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      old_revision = @repo.get_latest_revision()
      # add one more file
      filename = "ruby_file.rb"
      txn = @repo.get_transaction(TEST_USER)
      file_contents = File.read(RESOURCE_DIR+"/"+filename)
      txn.add("/"+filename, file_contents)
      
      # collect a timestamp for later use
      repo_timestamp = Time.now
      
      # remove a file
      txn.remove("/test.xml", @repo.get_latest_revision().revision_number) # remove a file previously existent in current rev.
      @repo.commit(txn)
      
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::MemoryRevision, old_revision, "Should be of type MemoryRevision")
      assert_instance_of(Repository::MemoryRevision, new_revision, "Should be of type MemoryRevision")
      assert_equal(old_revision.revision_number + 1, new_revision.revision_number, "Revision number should have been increased by 1")
      # test repository on its correct content
      files = new_revision.files_at_path("/")
      files_to_add << filename # push filename to files_to_add
      files_to_add.each do |file|
        if file != "test.xml"
          assert_not_nil(files[file], "File '"+file+"' not found in repository")
          content = File.read(RESOURCE_DIR+"/"+file)
          # test stringify_files also
          assert_equal(content, @repo.stringify_files(files[file]))
        end
      end
      
      # test the timestamp-revision stuff
      rev_num_by_timestamp = @repo.get_revision_by_timestamp(Time.now)
      latest_rev = @repo.get_latest_revision()
      assert_instance_of(Repository::MemoryRevision, rev_num_by_timestamp, "Revision number is of wrong type")
      assert_instance_of(Repository::MemoryRevision, latest_rev, "Revision number is of wrong type")
      assert_equal(rev_num_by_timestamp.revision_number, latest_rev.revision_number, "Revision number (int values) do not match")
      
      # test.xml should be in the repository for the timestamp "repo_timestamp"
      rev_num_by_timestamp = @repo.get_revision_by_timestamp(repo_timestamp)
      assert_instance_of(Repository::MemoryRevision, rev_num_by_timestamp, "Revision number is of wrong type")
      files = rev_num_by_timestamp.files_at_path("/")
      files_to_add.each do |file|
        if file == "test.xml"
          assert_not_nil(files[file], "File '"+file+"' not found in repository")
          content = File.read(RESOURCE_DIR+"/"+file)
          # test stringify_files also
          assert_equal(content, @repo.stringify_files(files[file]))
        end
      end
    end
    
    should "be able to add a user with a given permission set to a repository" do
      # permissions are read-only and read-write
    end
    
    should "be able to remove a user from a repository" do
      # test removal of non-existent user
      
    end
    
    should "be able to get a list of users with particular permissions" do
      
    end
    
    should "be able to get permissions for a particular user" do
      
    end
    
  end # end context
  
  private # private helper methods for this class
  def add_file_helper(repo, file)
    txn = repo.get_transaction(TEST_USER)
    file_contents = File.read(RESOURCE_DIR+"/"+file)
    if File.dirname(file) == "."
      prefix = "/"
    else
      prefix = ""
    end
    txn.add(prefix+file, file_contents)
    repo.commit(txn)
  end
  
  def add_some_files_helper(repo, files)
    txn = repo.get_transaction(TEST_USER)
    files.each do |file|
      if File.dirname(file) == "."
        prefix = "/"
      else
        prefix = ""
      end
      txn.add(prefix+file, File.read(RESOURCE_DIR+"/"+file))
    end
    repo.commit(txn)
  end
  
end # end class MemoryRepositoryTest

# Test suite for testing proper functioning of 
# MemoryRevision, an implementation of AbstractRevision
class MemoryRevisionTest < Test::Unit::TestCase
  
  RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__),"/input_files"))
  TEST_USER = "testuser"
  
  context "A MemoryRevision object" do
    
    setup do
      @mem_rev = MemoryRevision.new(0) # create new revision
      # add some files to revision
      dir1 = RevisionDirectory.new( @mem_rev.revision_number, {
          :name => "dir_1",
          :path => "/",
          :last_modified_revision => @mem_rev.revision_number,
          :changed => true,
          :user_id => TEST_USER
      })
      file1 = RevisionFile.new( @mem_rev.revision_number, {
          :name => "MyClass.java",
          :path => "/dir_1", # put MyClass.java into directory "dir_1"
          :last_modified_revision => @mem_rev.revision_number,
          :changed => true,
          :user_id => TEST_USER
      })
      file2 = RevisionFile.new( @mem_rev.revision_number, {
          :name => "MyInterface.java",
          :path => "/dir_1",
          :last_modified_revision => @mem_rev.revision_number,
          :changed => true,
          :user_id => TEST_USER
      })
      file3 = RevisionFile.new( @mem_rev.revision_number, {
          :name => "test.xml",
          :path => "/",
          :last_modified_revision => @mem_rev.revision_number,
          :changed => true,
          :user_id => TEST_USER
      })      
      @mem_rev.__add_file(file3, File.read(RESOURCE_DIR+"/"+file3.name))
      @mem_rev.__add_file(file1, File.read(RESOURCE_DIR+"/"+file1.name))
      @mem_rev.__add_file(file2, File.read(RESOURCE_DIR+"/"+file2.name))
      @mem_rev.__add_directory(dir1)
    end
    
    should "know if a path exists in its revision" do      
      assert_equal(true, @mem_rev.path_exists?("/dir_1"), "Path '/dir_1' should exists in this revision")
      assert_equal(false, @mem_rev.path_exists?("/test"), "Path '/test' should NOT exist in this revision")
    end
    
    should "know about files at a certain path and be able to read its content" do      
      files = @mem_rev.files_at_path("/dir_1")
      files.each do |filename, object|
        assert_equal(File.read(RESOURCE_DIR+"/"+filename), @mem_rev.files_content[object.to_s], "Content mismatch")
      end
      filenames = files.keys().sort()
      assert_equal("MyInterface.java", filenames.last(), "File not found")
      assert_equal("MyClass.java", filenames[0], "File not found")
      files = @mem_rev.files_at_path("/")
      assert_equal("test.xml", files.keys()[0], "Wrong filename!")
      assert_equal(File.read(RESOURCE_DIR+"/"+files.keys()[0]), @mem_rev.files_content[files[files.keys()[0]].to_s], "Content mismatch")
      files = @mem_rev.files_at_path("/some/not/existent/path")
      assert_equal({}, files, "There shouldn't be any files")
    end
    
    should "know about directories at a certain path" do
      dirs = @mem_rev.directories_at_path("/")
      assert_equal(1, dirs.keys().length(), "Wrong number of directories")
      assert_equal("dir_1", dirs.keys()[0], "Name of directory is wrong!")
      dirs = @mem_rev.directories_at_path("/some/non-existent/path")
      assert_equal(true, dirs.empty?, "There is no directory there!")
    end
    
    should "provide me with a set of changed files in this revision" do
      mem_rev = MemoryRevision.new(0) # create new revision
      # add some files to revision
      dir1 = RevisionDirectory.new( mem_rev.revision_number, {
          :name => "dir_1",
          :path => "/",
          :last_modified_revision => mem_rev.revision_number,
          :changed => false,
          :user_id => TEST_USER
      })
      file1 = RevisionFile.new( mem_rev.revision_number, {
          :name => "MyClass.java",
          :path => "/dir_1", # put MyClass.java into directory "dir_1"
          :last_modified_revision => mem_rev.revision_number,
          :changed => true,
          :user_id => TEST_USER
      })
      file2 = RevisionFile.new( mem_rev.revision_number, {
          :name => "MyInterface.java",
          :path => "/dir_1",
          :last_modified_revision => mem_rev.revision_number,
          :changed => false,
          :user_id => TEST_USER
      })
      file3 = RevisionFile.new( mem_rev.revision_number, {
          :name => "test.xml",
          :path => "/",
          :last_modified_revision => mem_rev.revision_number,
          :changed => true,
          :user_id => TEST_USER
      })      
      mem_rev.__add_file(file3, File.read(RESOURCE_DIR+"/"+file3.name))
      mem_rev.__add_file(file2, File.read(RESOURCE_DIR+"/"+file2.name))
      mem_rev.__add_file(file1, File.read(RESOURCE_DIR+"/"+file1.name))
      @mem_rev.__add_directory(dir1)
      
      files = mem_rev.changed_files_at_path("/")
      assert_equal("test.xml", files.keys()[0], "Wrong filename!")
      assert_equal(File.read(RESOURCE_DIR+"/"+files.keys()[0]), mem_rev.files_content[files[files.keys()[0]].to_s], "Content mismatch")
      files = mem_rev.changed_files_at_path("/dir_1")
      assert_equal("MyClass.java", files.keys()[0], "Wrong filename!")
      assert_equal(File.read(RESOURCE_DIR+"/"+files.keys()[0]), mem_rev.files_content[files[files.keys()[0]].to_s], "Content mismatch")
      files = mem_rev.changed_files_at_path("/some/not/existent/path")
      assert_equal({}, files, "There shouldn't be any files")
      
      # more testing
      mem_rev = MemoryRevision.new(0) # create new revision
      file1 = RevisionFile.new( mem_rev.revision_number, {
          :name => "MyClass.java",
          :path => "/",
          :last_modified_revision => mem_rev.revision_number,
          :changed => false,
          :user_id => TEST_USER
      })
      mem_rev.__add_file(file1, File.read(RESOURCE_DIR+"/"+file1.name))
      files = mem_rev.changed_files_at_path("/")
      assert_equal({}, files, "There shouldn't be any _CHANGED_ files")
    end
  end # end context
end # end class MemoryRevisionTest
