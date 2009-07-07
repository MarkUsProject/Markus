require File.join(File.dirname(__FILE__),'/../subversion_repository')
require 'test/unit' # load Test::Unit
require 'rubygems'
require 'fileutils'
require 'shoulda'   # load Thoughtbot Shoulda (used as testing framework)
require 'time'

# bring Repository::SubversionRepository into current namespace
include Repository

# Test suite for testing proper functioning of 
# SubversionRepository, an implementation of AbstractRepository
class SubversionRepositoryTest < Test::Unit::TestCase
  
  SVN_TEST_REPOS_DIR = File.expand_path(File.join(File.dirname(__FILE__),"/svn_repos"))
  TEST_REPO = SVN_TEST_REPOS_DIR + "/repo1"
  RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__),"/input_files"))
  TEST_USER = "testuser"
  
  context "SubversionRepository class" do
    
    teardown do
      FileUtils.remove_dir(TEST_REPO, true)
    end
    
    should "be able to create a new Subversion repository" do
      SubversionRepository.create(TEST_REPO)
      assert_equal(File.exists?(TEST_REPO), true, "Unable to creat a Subversion repository")
    end
    
    should "be able to open an existing Subversion repository" do
      SubversionRepository.create(TEST_REPO)
      repo = SubversionRepository.open(TEST_REPO)
      assert_not_nil(repo, "Cannot open supversion repository")
      assert_instance_of(Repository::SubversionRepository, repo, "Repository is of wrong type")
    end
    
    should "know if a Subversion repository exists at some place" do
      SubversionRepository.create(TEST_REPO)
      assert_equal(SubversionRepository.repository_exists?(TEST_REPO), true, "A SVN repository should exist at: '"+TEST_REPO+"'")
    end
  end
  
  context "A SubversionRepository instance" do
    
    # setup and teardown for the current context
    
    # creates a new SVN repository at TEST_REPO
    setup do
      # create repository first
      SubversionRepository.create(TEST_REPO)
      # open the repository
      @repo = SubversionRepository.new(TEST_REPO)      
    end
    
    # removes the SVN repository at TEST_REPO
    teardown do
      FileUtils.remove_dir(TEST_REPO, true)
    end
    
    # beginning of tests
   
    should "have been instanciated and a Subversion repository in the filesystem created" do
      assert_not_nil(@repo, "Could not create/open Repository: look into the tests' setup")
    end
    
    should "provide a transaction" do
      transaction = @repo.get_transaction(TEST_USER)
      assert_not_nil(transaction, "Could not retrieve transaction")
      assert_instance_of(Repository::Transaction, transaction, "Transaction is not of correct type!")
    end
    
    should "give the latest revision" do
      revision = @repo.get_latest_revision()
      assert_not_nil(revision, "Could not retrieve latest revision")
      assert_instance_of(Repository::SubversionRevision, revision, "Revision is of wrong type!")
      assert_equal(revision.revision_number, 0, "Wrong revision number")
    end
    
    should "be able to retrieve a revision given a valid revision as integer number" do
      r = @repo.get_latest_revision()
      assert_not_nil(r, "Could not retrieve latest revision")
      rev_int = r.revision_number
      new_revision = @repo.get_revision(rev_int)
      assert_instance_of(Repository::SubversionRevision, new_revision, "Revision not of class SubversionRevision")
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
      txn.add(filename, file_contents)
      latest_revision = @repo.get_latest_revision().revision_number
      assert_equal(rev_num, latest_revision, "Revision # should be the same!")
      @repo.commit(txn) # svn commit
      latest_revision = @repo.get_latest_revision().revision_number
      
      assert_not_equal(rev_num, latest_revision, "Revision # has not changed!")
      
      # look if new file is available
      svn_rev = @repo.get_latest_revision()
      files = svn_rev.files_at_path("/")
      assert_not_nil(files[filename], "Could not find file '"+filename+"'")
      # test download_as_string
      assert_equal(@repo.download_as_string(files[filename]), file_contents, "Mismatching content")
    end
    
    should "delete a commited file from repository" do
      add_file_test.intern() # call add_file_test to make sure it works, not sure if that's useful
      # add MyClass.java to repo
      filename = "MyClass.java"
      add_file_helper(@repo, filename)
      txn = @repo.get_transaction(TEST_USER)
      txn.remove(filename, @repo.get_latest_revision().revision_number)
      @repo.commit(txn)
      
      # filename should not be available in repo now
      svn_rev = @repo.get_latest_revision()
      files = svn_rev.files_at_path("/")
      assert_nil(files[filename], "File '"+filename+"' should have been removed!")
    end
    
    should "be able to add multiple files using a single transaction" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      old_revision = @repo.get_latest_revision()
      add_some_files_helper(@repo, files_to_add)
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::SubversionRevision, old_revision, "Should be of type SubversionRevision")
      assert_instance_of(Repository::SubversionRevision, new_revision, "Should be of type SubversionRevision")
      assert_equal(old_revision.revision_number + 1, new_revision.revision_number, "Revision number should increase by 1")
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
      txn.add(filename, file_contents)
      # remove a file
      txn.remove("test.xml", @repo.get_latest_revision().revision_number) # remove a file previously existent in current rev.
      @repo.commit(txn)
      
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::SubversionRevision, old_revision, "Should be of type SubversionRevision")
      assert_instance_of(Repository::SubversionRevision, new_revision, "Should be of type SubversionRevision")
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
      txn.add(filename, file_contents)
      
      # collect a timestamp for later use
      repo_timestamp = Time.now
      
      # remove a file
      txn.remove("test.xml", @repo.get_latest_revision().revision_number) # remove a file previously existent in current rev.
      @repo.commit(txn)     
      
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::SubversionRevision, old_revision, "Should be of type SubversionRevision")
      assert_instance_of(Repository::SubversionRevision, new_revision, "Should be of type SubversionRevision")
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
      assert_instance_of(Repository::SubversionRevision, rev_num_by_timestamp, "Revision number is of wrong type")
      assert_instance_of(Repository::SubversionRevision, latest_rev, "Revision number is of wrong type")
      assert_equal(rev_num_by_timestamp.revision_number, latest_rev.revision_number, "Revision number (int values) do not match")
      
      # test.xml should be in the repository for the timestamp "repo_timestamp"
      rev_num_by_timestamp = @repo.get_revision_by_timestamp(repo_timestamp)
      assert_instance_of(Repository::SubversionRevision, rev_num_by_timestamp, "Revision number is of wrong type")
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
    
    # TODO: write add_user, get_users, remove_user tests
    
  end # end context
  
  context "A repository with some files in it" do
    
    setup do
      # create repository first
      SubversionRepository.create(TEST_REPO)
      # open the repository
      @repo = SubversionRepository.new(TEST_REPO)
      # add some files
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add)
    end
    
    # TODO: should we write some more tests here?

  end # end context
  
  private # private helper methods for this class
    
  def add_file_helper(repo, file)
    txn = repo.get_transaction(TEST_USER)
    file_contents = File.read(RESOURCE_DIR+"/"+file)
    txn.add(file, file_contents)
    repo.commit(txn)
  end
  
  def add_some_files_helper(repo, files)
    txn = repo.get_transaction(TEST_USER)
    files.each do |file|
      txn.add(file, File.read(RESOURCE_DIR+"/"+file))
    end
    repo.commit(txn)
  end
  
end # end class SubversionRepositoryTest

# Test suite for testing proper functioning of 
# SubversionRevision, an implementation of AbstractRevision
class SubversionRevisionTest < Test::Unit::TestCase
  # TODO: Test SubversionRevision here
end