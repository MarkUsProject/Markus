require File.expand_path(File.join(File.dirname(__FILE__),'..', 'memory_repository'))
require 'test/unit'
require 'rubygems'
require 'shoulda'   # load Thoughtbot Shoulda (used as testing framework)
require 'time'
include Repository # bring Repository module into current namespace

class MemoryRepositoryTest < ActiveSupport::TestCase

  RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__), "input_files"))
  TEST_USER = "testuser"
  REPO_LOCATION = File.expand_path(File.join(File.dirname(__FILE__),'memory_repo1'))
  ANOTHER_REPO_LOCATION = File.expand_path(File.join(File.dirname(__FILE__),'memory_repo2'))
  # following constant not used as of now
  TEST_REPO_CONTENT = File.expand_path(File.join(File.dirname(__FILE__),'..', 'memory_repository.yml'))

  context "MemoryRepository class" do

    teardown do
      MemoryRepository.purge_all()
    end

    should "be able to create a new Memory repository" do
      MemoryRepository.create(REPO_LOCATION)
      repo = MemoryRepository.open(REPO_LOCATION)
      assert_not_nil(repo, "Could not create Repository")
      assert_instance_of(Repository::MemoryRepository, repo, "Repository is of wrong type")
      # and create another one :-)
      MemoryRepository.create(ANOTHER_REPO_LOCATION)
      repo2 = MemoryRepository.open(ANOTHER_REPO_LOCATION)
      assert_not_nil(repo2, "Could not create Repository")
      assert_instance_of(Repository::MemoryRepository, repo2, "Repository is of wrong type")
    end

    should "be able to open an existing Memory repository" do
      MemoryRepository.create(REPO_LOCATION)
      MemoryRepository.create(ANOTHER_REPO_LOCATION) # create another one
      repo = MemoryRepository.open(REPO_LOCATION) # open repository created first
      assert_not_nil(repo, "Cannot open memory repository")
      assert_instance_of(Repository::MemoryRepository, repo, "Repository is of wrong type")
    end

    should "be able to access an existing Memory repository" do
      MemoryRepository.create(REPO_LOCATION)
      MemoryRepository.create(ANOTHER_REPO_LOCATION) # create another one
      MemoryRepository.access(REPO_LOCATION) do |repo| # access repository created first
        assert_not_nil(repo, "Cannot open memory repository")
        assert_instance_of(Repository::MemoryRepository, repo, "Repository is of wrong type")
      end
    end

    should "be able to delete a Memory repository" do
      MemoryRepository.create(REPO_LOCATION)
      MemoryRepository.delete(REPO_LOCATION)
      assert(!MemoryRepository.repository_exists?(REPO_LOCATION), "Did not properly delete the repository")
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
      @repo = MemoryRepository.open(REPO_LOCATION)
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

    should "know whether or not it is closed" do
      assert(!@repo.closed?, "opened repository identified as closed")
      @repo.close
      assert(@repo.closed?, "closed repository identified as open")
    end

    should "be able to create a directory in repository" do
      dir_single_level = "/folder1"
      dir_multi_level = "/folder2/subfolder1"

      txn = @repo.get_transaction(TEST_USER)
      txn.add_path(dir_single_level)
      txn.add_path(dir_multi_level)
      @repo.commit(txn)
      revision = @repo.get_latest_revision()

      assert_equal(true, revision.path_exists?(dir_single_level), message = "Repository folder not created")
      assert_equal(true, revision.path_exists?(dir_multi_level), message = "Repository folder not created")
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
      assert_equal(0, files.size, "File '"+filename+"' should have been removed!")
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

    should "be able to replace file-content of an already existing file in the repository" do
      # put something into the repository
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      old_revision = @repo.get_latest_revision()
      # add one more file
      filename = "ruby_file.rb"
      txn = @repo.get_transaction(TEST_USER)
      file_contents = File.read(RESOURCE_DIR+"/"+filename)
      txn.add("/"+filename, file_contents)
      @repo.commit(txn)
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::MemoryRevision, old_revision, "Should be of type MemoryRevision")
      assert_instance_of(Repository::MemoryRevision, new_revision, "Should be of type MemoryRevision")
      assert_equal(old_revision.revision_number + 1, new_revision.revision_number, "Revision number should have been increased by 1")
      # test repository on its correct content
      files = new_revision.files_at_path("/")
      files_to_add << filename # push filename to files_to_add
      files_to_add.each do |file|
        assert_not_nil(files[file], "File '"+file+"' not found in repository")
        content = File.read(RESOURCE_DIR+"/"+file)
        # test stringify_files also
        assert_equal(content, @repo.stringify_files(files[file]))
      end

      # replace content of a file
      old_revision = @repo.get_latest_revision()
      txn = @repo.get_transaction(TEST_USER)
      replace_content = '''<?xml version="1.0" encoding="utf-8" ?>
<book>
  <author>Leonardo da Vinci</author>
  <para>Some text here</para>
</book>'''
      # test if FileDoesNotExistConflict is raised
      txn.replace("/file/not/existent", replace_content, "application/xml", @repo.get_latest_revision().revision_number)
      assert_equal(false, @repo.commit(txn), "Commit should not have been successful")
      assert_equal(true, txn.conflicts?, "Transaction should have a FileDoesNotExistConflict")
      assert_raise(FileDoesNotExistConflict) do
        txn.conflicts().each do |conflict|
          raise conflict
        end
      end
      new_revision = @repo.get_latest_revision()
      assert_equal(old_revision.revision_number, new_revision.revision_number, "Revision number should not have been increased, since commit had conflicts!")

      # test clean replace
      txn = @repo.get_transaction(TEST_USER)
      txn.replace("/test.xml", replace_content, "application/xml", @repo.get_latest_revision().revision_number)
      @repo.commit(txn)
      new_revision = @repo.get_latest_revision()
      assert_instance_of(Repository::MemoryRevision, old_revision, "Should be of type MemoryRevision")
      assert_instance_of(Repository::MemoryRevision, new_revision, "Should be of type MemoryRevision")
      assert_equal(old_revision.revision_number + 1, new_revision.revision_number, "Revision number should have been increased by 1")
      # test repository on its correct content
      files = new_revision.files_at_path("/")
      assert_not_nil(files["test.xml"], "File 'test.xml' not found in repository")
      # test stringify_files also
      assert_equal(replace_content, @repo.stringify_files(files["test.xml"]), "Content mismatch")
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
          assert_not_nil(files[file], "File '" + file + "' not found in repository")
          content = File.read(RESOURCE_DIR+"/"+file)
          # test stringify_files also
          assert_equal(content, @repo.stringify_files(files[file]))
        end
      end
    end

    should "be able to manage users and permissions" do
      # tests
      #   'add_user()'
      #   'remove_user()'
      #   'get_permissions()'
      #   'set_permissions()
      #   'get_users()'
      another_user = "another_user_id"

      # check if permission constants are working
      assert_equal(2, Repository::Permission::WRITE)
      assert_equal(4, Repository::Permission::READ)
      assert_equal(6, Repository::Permission::READ_WRITE)
      assert_equal(4, Repository::Permission::ANY)

      users_with_any_perm = @repo.get_users(Repository::Permission::ANY)
      assert_nil(users_with_any_perm, "There aren't any users, yet")
      users_with_read_perm = @repo.get_users(Repository::Permission::READ)
      assert_nil(users_with_read_perm, "There aren't any users, yet")
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE)
      assert_nil(users_with_read_write_perm, "There aren't any users, yet")

      @repo.add_user(TEST_USER, Repository::Permission::READ)
      users_with_any_perm = @repo.get_users(Repository::Permission::ANY)
      assert_not_nil(users_with_any_perm, "There is a user with some permissions")
      assert_equal(TEST_USER, users_with_any_perm.shift, TEST_USER+ " should have some permissions")
      users_with_read_perm = @repo.get_users(Repository::Permission::READ)
      assert_not_nil(users_with_read_perm, TEST_USER+" should have read permissions")
      assert_equal(TEST_USER, users_with_read_perm.shift, TEST_USER+ " should have read permissions")
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE)
      assert_nil(users_with_read_write_perm, "There is no user with read and write permissions")
      # see if permissions have been set accordingly
      assert_equal(Repository::Permission::READ, @repo.get_permissions(TEST_USER), "Permissions don't match")

      # set (overwrite) permissions
      @repo.set_permissions(TEST_USER, Repository::Permission::READ_WRITE)
      assert_equal(Repository::Permission::READ_WRITE, @repo.get_permissions(TEST_USER), "Permissions don't match")
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE)
      assert_not_nil(users_with_read_write_perm, "There is a user with read and write permissions")
      assert_equal(TEST_USER, users_with_read_write_perm.shift, TEST_USER + " should have read and write permissions")

      # add another user
      @repo.add_user(another_user, Repository::Permission::READ)
      assert_equal(Repository::Permission::READ, @repo.get_permissions(another_user), "Permissions don't match")
      users_with_any_perm = @repo.get_users(Repository::Permission::ANY)
      assert_not_nil(users_with_any_perm, "There are some users with some permissions")
      assert_equal([TEST_USER, another_user].sort, users_with_any_perm.sort, "There are some missing users")
      users_with_read_perm = @repo.get_users(Repository::Permission::READ).sort
      assert_not_nil(users_with_read_perm, "Some user has read permissions")
      assert_equal(another_user, users_with_read_perm.shift, another_user + " should have read permissions")
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE)
      assert_not_nil(users_with_read_write_perm, "There are some users with read and write permissions")
      assert_equal(TEST_USER, users_with_read_write_perm.shift, TEST_USER + " should have read and write permissions")

      # remove user
      @repo.remove_user(TEST_USER)
      assert_equal(Repository::Permission::READ, @repo.get_permissions(another_user), "Permissions don't match")
      users_with_any_perm = @repo.get_users(Repository::Permission::ANY)
      assert_not_nil(users_with_any_perm, "There are some users with some permissions")
      assert_equal(another_user, users_with_any_perm.shift, another_user + " still has some perms")
      users_with_read_perm = @repo.get_users(Repository::Permission::READ).sort
      assert_not_nil(users_with_read_perm, "Some user has read permissions")
      assert_equal(another_user, users_with_read_perm.shift, another_user + " should have read permissions")
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE)
      assert_nil(users_with_read_write_perm, "There are NO users with read and write permissions")

      @repo.remove_user(another_user)
      users_with_any_perm = @repo.get_users(Repository::Permission::ANY)
      assert_nil(users_with_any_perm, "There are NO users with any permissions")

    end

    should "have repositories persist" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      revision1 = @repo.get_latest_revision()
      new_repo = MemoryRepository.open(REPO_LOCATION)
      revision2 = new_repo.get_latest_revision()
      assert_equal revision1.revision_number, revision2.revision_number, "These two revision numbers should match!"
    end

  end # end context

  context "MemoryRepository" do

    # setup and teardown for the current context

    # creates repositories
    setup do
      @repo_names = ["test_repo", "test_repo2", "test_repo3", "test_repo4"]
      # Create the repos
      @repo_names.each do |repo_name|
        MemoryRepository.create(repo_name)
      end
    end

    # destroy all repositories created
    teardown do
      MemoryRepository.purge_all()
    end

    should "raise an exception if not properly configured" do
      assert_raise(ConfigurationError) do
        Repository.get_class("memory") # missing required REPOSITORY_PERMISSION_FILE
      end
    end

    should "be able to bulk add and delete user permissions" do

      # Now lets try to bulk add some users
      MemoryRepository.set_bulk_permissions(@repo_names, {"test_user" => Repository::Permission::READ})
      MemoryRepository.set_bulk_permissions(@repo_names, {"test_user2" => Repository::Permission::READ_WRITE})
      MemoryRepository.set_bulk_permissions(@repo_names, {"test_user3" => Repository::Permission::READ})

      # Check to see if permissions were added
      @repo_names.each do |repo_name|
        repo = MemoryRepository.open(repo_name)
        assert_equal(Repository::Permission::READ, repo.get_permissions('test_user'))
        assert_equal(Repository::Permission::READ_WRITE, repo.get_permissions('test_user2'))
        assert_equal(Repository::Permission::READ, repo.get_permissions('test_user3'))
      end

      # Check to see if we can bulk delete
      MemoryRepository.delete_bulk_permissions(@repo_names, ['test_user', 'test_user2'])
      @repo_names.each do |repo_name|
        repo = MemoryRepository.open(repo_name)
        assert_raises Repository::UserNotFound do
          repo.get_permissions('test_user')
        end
        assert_raises Repository::UserNotFound do
          repo.get_permissions('test_user2')
        end
        assert_equal(Repository::Permission::READ, repo.get_permissions('test_user3'))
      end

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

  RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__),"input_files"))
  TEST_USER = "testuser"

  context "A MemoryRevision object" do

    setup do
      @mem_rev = MemoryRevision.new(0) # create new revision
      # add some files to revision
      dir1 = RevisionDirectory.new( @mem_rev.revision_number, {
          name: "dir_1",
          path: "/",
          last_modified_revision: @mem_rev.revision_number,
          changed: true,
          user_id: TEST_USER
      })
      file1 = RevisionFile.new( @mem_rev.revision_number, {
          name: "MyClass.java",
          path: "/dir_1", # put MyClass.java into directory "dir_1"
          last_modified_revision: @mem_rev.revision_number,
          changed: true,
          user_id: TEST_USER
      })
      file2 = RevisionFile.new( @mem_rev.revision_number, {
          name: "MyInterface.java",
          path: "/dir_1",
          last_modified_revision: @mem_rev.revision_number,
          changed: true,
          user_id: TEST_USER
      })
      file3 = RevisionFile.new( @mem_rev.revision_number, {
          name: "test.xml",
          path: "/",
          last_modified_revision: @mem_rev.revision_number,
          changed: true,
          user_id: TEST_USER
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
          name: "dir_1",
          path: "/",
          last_modified_revision: mem_rev.revision_number,
          changed: false,
          user_id: TEST_USER
      })
      file1 = RevisionFile.new( mem_rev.revision_number, {
          name: "MyClass.java",
          path: "/dir_1", # put MyClass.java into directory "dir_1"
          last_modified_revision: mem_rev.revision_number,
          changed: true,
          user_id: TEST_USER
      })
      file2 = RevisionFile.new( mem_rev.revision_number, {
          name: "MyInterface.java",
          path: "/dir_1",
          last_modified_revision: mem_rev.revision_number,
          changed: false,
          user_id: TEST_USER
      })
      file3 = RevisionFile.new( mem_rev.revision_number, {
          name: "test.xml",
          path: "/",
          last_modified_revision: mem_rev.revision_number,
          changed: true,
          user_id: TEST_USER
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
          name: "MyClass.java",
          path: "/",
          last_modified_revision: mem_rev.revision_number,
          changed: false,
          user_id: TEST_USER
      })
      mem_rev.__add_file(file1, File.read(RESOURCE_DIR+"/"+file1.name))
      files = mem_rev.changed_files_at_path("/")
      assert_equal({}, files, "There shouldn't be any _CHANGED_ files")
    end
  end # end context
end # end class MemoryRevisionTest
