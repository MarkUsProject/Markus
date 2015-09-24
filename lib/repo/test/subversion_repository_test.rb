require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'subversion_repository'))
require 'test/unit' # load Test::Unit
require 'rubygems'
require 'fileutils'
require 'shoulda'   # load Thoughtbot Shoulda (used as testing framework)
require 'time'

# bring Repository::SubversionRepository into current namespace
include Repository

# Test suite for testing proper functioning of
# SubversionRepository, an implementation of AbstractRepository
class SubversionRepositoryTest < ActiveSupport::TestCase

  SVN_TEST_REPOS_DIR = File.expand_path(File.join(File.dirname(__FILE__),"/svn_repos"))
  TEST_REPO = SVN_TEST_REPOS_DIR + "/repo1"
  TEST_EXPORT_REPO = SVN_TEST_REPOS_DIR + "/exported_repo1"
  TEST_EXPORT_REPO_2 = SVN_TEST_REPOS_DIR + "/exported_repo2"
  RESOURCE_DIR = File.expand_path(File.join(File.dirname(__FILE__),"/input_files"))
  TEST_USER = "testuser"

  context "SubversionRepository class" do

    teardown do
      FileUtils.remove_dir(TEST_REPO, true)
    end

    should "be able to create a new Subversion repository" do
       SubversionRepository.create(TEST_REPO)
      assert_equal(File.exists?(TEST_REPO),
                   true,
                   "Unable to creat a Subversion repository")
    end

    should "be able to open an existing Subversion repository" do
      SubversionRepository.create(TEST_REPO)
      repo = SubversionRepository.open(TEST_REPO)
      assert_not_nil(repo, "Cannot open subversion repository")
      assert_instance_of(Repository::SubversionRepository,
                         repo,
                         "Repository is of wrong type")
      repo.close()
    end

    should "be able to access an existing Subversion repository" do
      SubversionRepository.create(TEST_REPO)
      SubversionRepository.access(TEST_REPO) do |repo|
        assert_not_nil(repo, "Cannot access supversion repository")
        assert_instance_of(Repository::SubversionRepository,
                           repo,
                           "Repository is of wrong type")
      end
    end

    should "know if a Subversion repository exists at some place" do
      SubversionRepository.create(TEST_REPO)
      assert_equal(SubversionRepository.repository_exists?(TEST_REPO),
                   true,
                   "A SVN repository should exist at: '" + TEST_REPO + "'")
    end

    should "be able to delete a Subversion repository" do
      SubversionRepository.create(TEST_REPO)
      SubversionRepository.delete(TEST_REPO)
      assert(!File.exists?(TEST_REPO), "Did not properly delete the repository")
    end
  end

  context "A SubversionRepository instance" do

    # setup and teardown for the current context

    # creates a new SVN repository at TEST_REPO
    setup do
      #make sure there is not a leftover directory here from a previous run
      FileUtils.remove_dir(TEST_REPO, true)
      FileUtils.mkdir_p(TEST_EXPORT_REPO_2)
      # configure and create repositories
      conf_admin = Hash.new
      conf_admin["IS_REPOSITORY_ADMIN"] = true
      conf_admin["REPOSITORY_PERMISSION_FILE"] = SVN_AUTHZ_FILE
      # create repository first
      Repository.get_class("svn", conf_admin).create(TEST_REPO)
      # open the repository
      @repo = Repository.get_class("svn", conf_admin).open(TEST_REPO)
    end

    # removes the SVN repository at TEST_REPO
    teardown do
      if !@repo.nil? and !@repo.closed?
        @repo.close()
      end
      FileUtils.remove_dir(TEST_REPO, true)
      FileUtils.remove_dir(TEST_EXPORT_REPO, true)
      FileUtils.remove_dir(TEST_EXPORT_REPO_2, true)
    end

    # beginning of tests

    should "have exported the Subversion repository" do
      assert_not_nil(@repo.export(TEST_EXPORT_REPO),
                     "Did not properly export svn repository")
      assert(File.exists?(TEST_EXPORT_REPO),
             "Did not properly export svn repository")
      @repo.close()
    end

    should "export one file of the Subversion repository into a file" do
      file = "not-on-the-shelves-2009.pdf"

      # Let's start by adding the file to the svn repository
      add_file_helper(@repo, file)
      assert_not_nil(@repo.export("myfile.pdf",
                                  file),
                     "Did not properly export the file from the svn repo")
      assert(File.exists?("myfile.pdf"),
             "The file does not exist in the destination repository")

      FileUtils.remove_file("myfile.pdf", true)
      @repo.close()
    end

    should "export one file of the Subversion repository into a repository" do
      file = "not-on-the-shelves-2009.pdf"
      repo_to_export_to = File.join(TEST_EXPORT_REPO_2, file)
      # Let's start by adding the file to the svn repository
      add_file_helper(@repo, file)
      assert_not_nil(@repo.export(repo_to_export_to,
                                  file),
                     "Did not properly export the file from the svn repo")
      assert(File.exists?(repo_to_export_to),
             "The file does not exist in the destination repository")
      @repo.close()
    end


    should "raise an error if the repository where you want to export exists" do
      @repo.export(TEST_EXPORT_REPO)
      assert_raise(ExportRepositoryAlreadyExists) do
        @repo.export(TEST_EXPORT_REPO)
      end
    end

    should "have been instanciated and a Subversion repository in the filesystem created" do
      assert_not_nil(@repo, "Could not create/open Repository: look into the tests' setup")
      @repo.close()
    end

    should "provide a transaction" do
      transaction = @repo.get_transaction(TEST_USER)
      assert_not_nil(transaction, "Could not retrieve transaction")
      assert_instance_of(Repository::Transaction, transaction, "Transaction is not of correct type!")
      @repo.close()
    end

    should "give the latest revision" do
      revision = @repo.get_latest_revision()
      assert_not_nil(revision, "Could not retrieve latest revision")
      assert_instance_of(Repository::SubversionRevision, revision, "Revision is of wrong type!")
      assert_equal(revision.revision_number, 0, "Wrong revision number")
      @repo.close()
    end

    should "be able to retrieve a revision given a valid revision as integer number" do
      r = @repo.get_latest_revision()
      assert_not_nil(r, "Could not retrieve latest revision")
      rev_int = r.revision_number
      new_revision = @repo.get_revision(rev_int)
      assert_instance_of(Repository::SubversionRevision, new_revision, "Revision not of class SubversionRevision")
      assert_equal(new_revision.revision_number, rev_int, "Revision numbers (int values) should be equal")
      @repo.close()
    end

    should "raise a RevisionDoesNotExist exception" do
      r = @repo.get_latest_revision()
      assert_not_nil(r, "Could not retrieve latest revision")
      revision_non_existent = r.revision_number + 3
      assert_raise(RevisionDoesNotExist) do
        @repo.get_revision(revision_non_existent) # raises exception
      end
      @repo.close()
    end

    should "be able to close its repository using the close() method" do
      @repo.close()
      FileUtils.remove_dir(TEST_REPO)#Will fail under Windows if not closed
    end

    should "know whether or not it is closed" do
      assert(!@repo.closed?, "opened repository identified as closed")
      @repo.close()
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
      @repo.close()
    end

    add_file_test = "add a new file to an empty repository"
    should(add_file_test) do
      rev_num = @repo.get_latest_revision().revision_number
      txn = @repo.get_transaction(TEST_USER)
      filename = "MyClass.java"
      file_contents = File.read(RESOURCE_DIR + "/" + filename)
      txn.add(filename, file_contents)
      latest_revision = @repo.get_latest_revision().revision_number
      assert_equal(rev_num, latest_revision, "Revision # should be the same!")
      @repo.commit(txn) # svn commit
      latest_revision = @repo.get_latest_revision().revision_number

      assert_not_equal(rev_num, latest_revision, "Revision # has not changed!")

      # look if new file is available
      svn_rev = @repo.get_latest_revision()
      files = svn_rev.files_at_path("/")
      assert_not_nil(files[filename], "Could not find file '" + filename + "'")
      # test download_as_string
      assert_equal(@repo.download_as_string(files[filename]),
                   file_contents,
                   "Mismatching content")
      @repo.close()
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
      assert_nil(files[filename], "File '" + filename + "' should have been removed!")
      @repo.close()
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
        assert_not_nil(files[file], "File '" + file + "' not found in repository")
        content = File.read(RESOURCE_DIR + "/" + file)
        # test stringify_files also
        assert_equal(content, @repo.stringify_files(files[file]))
      end
      @repo.close()
    end

    should "be able to add, remove using a single transaction" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      old_revision = @repo.get_latest_revision()
      # add one more file
      filename = "ruby_file.rb"
      txn = @repo.get_transaction(TEST_USER)
      file_contents = File.read(RESOURCE_DIR + "/" + filename)
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
          assert_not_nil(files[file], "File '" + file + "' not found in repository")
          content = File.read(RESOURCE_DIR + "/" + file)
          # test stringify_files also
          assert_equal(content, @repo.stringify_files(files[file]))
        end
      end
      @repo.close()
    end

    should "be able to get a revision by timestamp" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      old_revision = @repo.get_latest_revision()
      # add one more file
      filename = "ruby_file.rb"
      txn = @repo.get_transaction(TEST_USER)
      file_contents = File.read(RESOURCE_DIR + "/" + filename)
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
          assert_not_nil(files[file], "File '" + file + "' not found in repository")
          content = File.read(RESOURCE_DIR + "/" + file)
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
          assert_not_nil(files[file], "File '" + file + "' not found in repository")
          content = File.read(RESOURCE_DIR + "/" + file)
          # test stringify_files also
          assert_equal(content, @repo.stringify_files(files[file]))
        end
      end
      @repo.close()
    end

    should "be able to get the last_modified_date of a file" do
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo, files_to_add) # add some initial files
      revision = @repo.get_latest_revision

      files_to_add.each do |file_name|
        assert_not_nil revision.files_at_path('/')[file_name].last_modified_date
        assert (revision.files_at_path('/')[file_name].last_modified_date - Time.now) < 1
      end

      txn = @repo.get_transaction(TEST_USER)
      txn.replace('MyClass.java', 'new data', 'text', 1)
      @repo.commit(txn)

      new_revision = @repo.get_latest_revision
      assert_not_nil new_revision.files_at_path('/')['MyClass.java'].last_modified_date
      assert_not_equal new_revision.files_at_path('/')['MyClass.java'].last_modified_date, revision.files_at_path('/')['MyClass.java'].last_modified_date
      @repo.close()
    end

  end # end context

  context "A repository with an authorization file specified" do

    SVN_AUTHZ_FILE = SVN_TEST_REPOS_DIR + "/svn_authz"

    setup do
      #cleanup any files that may be left over
      FileUtils.remove_dir(SVN_TEST_REPOS_DIR + "/Testrepo1", true)
      FileUtils.remove_dir(SVN_TEST_REPOS_DIR + "/Repository2", true)
      FileUtils.remove_dir(TEST_REPO, true)
      FileUtils.rm(SVN_AUTHZ_FILE, force: true)
      # have a clean authz file
      FileUtils.cp(SVN_AUTHZ_FILE + '.orig', SVN_AUTHZ_FILE)
      # create repository first
      repo1 = SVN_TEST_REPOS_DIR + "/Testrepo1"
      repo2 = SVN_TEST_REPOS_DIR + "/Repository2"
      conf_admin = Hash.new
      conf_admin["IS_REPOSITORY_ADMIN"] = true
      conf_admin["REPOSITORY_PERMISSION_FILE"] = SVN_AUTHZ_FILE
      Repository.get_class("svn", conf_admin).create(repo1)
      Repository.get_class("svn", conf_admin).create(repo2)
      Repository.get_class("svn", conf_admin).create(TEST_REPO)
      # open the repository
      conf_non_admin = Hash.new
      conf_non_admin["IS_REPOSITORY_ADMIN"] = false
      conf_non_admin["REPOSITORY_PERMISSION_FILE"] = SVN_AUTHZ_FILE

      @repo1 = Repository.get_class("svn", conf_non_admin).open(repo1) # non-admin repository
      @repo2 = Repository.get_class("svn", conf_non_admin).open(repo2) # again, a non-admin repo
      @repo = Repository.get_class("svn", conf_admin).open(TEST_REPO)     # repo with admin-privs

      # add some files
      files_to_add = ["MyClass.java", "MyInterface.java", "test.xml"]
      add_some_files_helper(@repo1, files_to_add)
      add_some_files_helper(@repo2, files_to_add)
    end

    # removes Subversion repositories
    teardown do
      if !@repo.nil? and !@repo.closed?
        @repo.close()
        @repo1.close()
        @repo2.close()
      end
      SubversionRepository.delete(SVN_TEST_REPOS_DIR + "/Testrepo1")
      SubversionRepository.delete(SVN_TEST_REPOS_DIR + "/Repository2")
      SubversionRepository.delete(TEST_REPO)
      FileUtils.rm(SVN_AUTHZ_FILE, force: true)
    end

    should "be able to get permissions for a user" do
      # check if permission constants are working
      assert_equal(2, Repository::Permission::WRITE)
      assert_equal(4, Repository::Permission::READ)
      assert_equal(6, Repository::Permission::READ_WRITE)
      assert_equal(4, Repository::Permission::ANY)

      assert_equal(Repository::Permission::READ_WRITE, @repo1.get_permissions("user1"))
      assert_equal(Repository::Permission::READ, @repo1.get_permissions("someother_user"))
      assert_equal(Repository::Permission::READ, @repo2.get_permissions("test"))

      #For some reason it does not work to just put these lines in the teardown
      @repo.close()
      @repo1.close()
      @repo2.close()
    end

    should "raise a UserNotFound exception" do
      # check if permission constants are working
      assert_equal(2, Repository::Permission::WRITE)
      assert_equal(4, Repository::Permission::READ)
      assert_equal(6, Repository::Permission::READ_WRITE)
      assert_equal(4, Repository::Permission::ANY)

      assert_raise(UserNotFound) do
        @repo1.get_permissions("non_existent_user")
      end
      assert_raise(UserNotFound) do
        @repo2.get_permissions("non_existent_user")
      end
      assert_raise(UserNotFound) do
        @repo.set_permissions("non_existent_user", Repository::Permission::READ_WRITE)
      end
      assert_raise(UserNotFound) do
        @repo.remove_user("non_existent_user")
      end
      @repo.close()
      @repo1.close()
      @repo2.close()
    end

    should "raise a UserAlreadyExistent exception" do
      # check if permission constants are working
      assert_equal(2, Repository::Permission::WRITE)
      assert_equal(4, Repository::Permission::READ)
      assert_equal(6, Repository::Permission::READ_WRITE)
      assert_equal(4, Repository::Permission::ANY)

      @repo.add_user("user_x", Repository::Permission::READ)
      assert_raise(UserAlreadyExistent) do
        @repo.add_user("user_x", Repository::Permission::READ_WRITE) # user_x exists already
      end
      @repo.close()
      @repo1.close()
      @repo2.close()
    end

    should "not be allowed to modify permissions when not it authoritative mode" do
      # check if permission constants are working
      assert_equal(2, Repository::Permission::WRITE)
      assert_equal(4, Repository::Permission::READ)
      assert_equal(6, Repository::Permission::READ_WRITE)
      assert_equal(4, Repository::Permission::ANY)

      assert_raise(NotAuthorityError) do
        @repo1.add_user("user_x", Repository::Permission::READ)
      end
      assert_raise(NotAuthorityError) do
        @repo2.set_permissions("test", Repository::Permission::READ_WRITE)
      end
      assert_raise(NotAuthorityError) do
        @repo2.remove_user("test")
      end
      @repo.close()
      @repo1.close()
      @repo2.close()
    end

    should "be able to add a user" do
      # check if permission constants are working
      assert_equal(2, Repository::Permission::WRITE)
      assert_equal(4, Repository::Permission::READ)
      assert_equal(6, Repository::Permission::READ_WRITE)
      assert_equal(4, Repository::Permission::ANY)
      @repo.add_user(TEST_USER, Repository::Permission::READ)
      assert_equal(Repository::Permission::READ, @repo.get_permissions(TEST_USER))
      @repo.close()
      @repo1.close()
      @repo2.close()
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
      assert_equal(TEST_USER, users_with_any_perm.shift, TEST_USER + " should have some permissions")
      users_with_read_perm = @repo.get_users(Repository::Permission::READ)
      assert_not_nil(users_with_read_perm, TEST_USER + " should have read permissions")
      assert_equal(TEST_USER, users_with_read_perm.shift, TEST_USER + " should have read permissions")
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
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE).sort
      assert_not_nil(users_with_read_write_perm, "There are some users with read and write permissions")
      assert_equal(TEST_USER, users_with_read_write_perm.shift, TEST_USER + " should have read and write permissions")

      # remove user
      @repo.remove_user(TEST_USER)
      assert_equal(Repository::Permission::READ, @repo.get_permissions(another_user), "Permissions don't match")
      users_with_any_perm = @repo.get_users(Repository::Permission::ANY).sort
      assert_not_nil(users_with_any_perm, "There are some users with some permissions")
      assert_equal(another_user, users_with_any_perm.shift, another_user +" still has some perms")
      users_with_read_perm = @repo.get_users(Repository::Permission::READ).sort
      assert_not_nil(users_with_read_perm, "Some user has read permissions")
      assert_equal(another_user, users_with_read_perm.shift, another_user + " should have read permissions")
      users_with_read_write_perm = @repo.get_users(Repository::Permission::READ_WRITE)
      assert_nil(users_with_read_write_perm, "There are NO users with read and write permissions")

      @repo.remove_user(another_user)
      users_with_any_perm = @repo.get_users(Repository::Permission::ANY)
      assert_nil(users_with_any_perm, "There are NO users with any permissions")
      @repo.close()
      @repo1.close()
      @repo2.close()
    end

  end # end context

  context "Looping over several repositories" do

    should "add a user per each repository" do
      # use a different svn_authz file for this test
      old_svn_authz = SVN_AUTHZ_FILE
      new_svn_authz = SVN_TEST_REPOS_DIR + "/svn_authz_bulk_stuff"

      # remove authz file if it exists
      if File.exist?(new_svn_authz)
        FileUtils.rm(new_svn_authz)
      end

      # create some repositories, add some users
      repo_base_name = SVN_TEST_REPOS_DIR + "/Group_"
      repository_names = []
      (1..5).each do |counter|
        repository_names.push(repo_base_name + counter.to_s.rjust(3, "0"))
      end

      # remove repositories, if they exist
      repository_names.each do |repo_name|
        if SubversionRepository.repository_exists?(repo_name)
          SubversionRepository.delete(repo_name)
        end
      end

      repositories = []
      conf_admin = Hash.new
      conf_admin["IS_REPOSITORY_ADMIN"] = true
      conf_admin["REPOSITORY_PERMISSION_FILE"] = SVN_AUTHZ_FILE
      repository_names.each do |repo_name|
        Repository.get_class("svn", conf_admin).create(repo_name)
        repo = Repository.get_class("svn", conf_admin).open(repo_name)
        repo.add_user("some_user", Repository::Permission::READ_WRITE)
        repo.add_user("another_user", Repository::Permission::READ_WRITE)
        repositories.push(repo)
      end

      # add a user for each repository
      repositories.each do |repo|
        repo.add_user(TEST_USER, Repository::Permission::READ_WRITE)
      end

      # assertions
      repositories.each do |r|
        assert_equal(Repository::Permission::READ_WRITE, r.get_permissions(TEST_USER))
      end

      #close all repositories
      repositories.each do |repo|
        repo.close()
      end
      # remove repositories repositories created
      repository_names.each do |repo_name|
        SubversionRepository.delete(repo_name)
      end

    end
  end # end context

  context "SubversionRepository" do
    should "raise an exception if not properly configured" do
      conf = Hash.new
      conf["REPOSITORY_PERMISSION_FILE"] = 'something'
      assert_raise(ConfigurationError) do
        Repository.get_class("svn", conf) # missing a required constant
      end
    end
  end # end context

  context "Setting and deleting bulk permissions" do
    setup do
      # use a different svn_authz file for this test
      new_svn_authz = SVN_TEST_REPOS_DIR + "/svn_authz_bulk_stuff2"
      @conf_admin = Hash.new
      @conf_admin["IS_REPOSITORY_ADMIN"] = true
      @conf_admin["REPOSITORY_PERMISSION_FILE"] = new_svn_authz

      # create some repositories, add some users
      repo_base_name = "Group_"
      @repository_names = []
      (1..5).each do |counter|
        @repository_names.push(repo_base_name + counter.to_s.rjust(3, "0"))
      end

      @repositories = []
      @repository_names.each do |repo_name|
        Repository.get_class("svn", @conf_admin).create(SVN_TEST_REPOS_DIR + "/" + repo_name)
        repo = Repository.get_class("svn", @conf_admin).open(SVN_TEST_REPOS_DIR + "/" + repo_name)
        @repositories.push(repo)
      end
    end

    teardown do
      new_svn_authz = SVN_TEST_REPOS_DIR + "/svn_authz_bulk_stuff2"
      # remove authz file if it exists
      if File.exist?(new_svn_authz)
        FileUtils.rm(new_svn_authz)
      end

      # remove repositories, if they exist
      @repository_names.each do |repo_name|
        if SubversionRepository.repository_exists?(SVN_TEST_REPOS_DIR + "/" + repo_name)
          SubversionRepository.delete(SVN_TEST_REPOS_DIR + "/" + repo_name)
        end
      end
    end

    should "Add a user and set permissions to every Group repository" do

      # Ok, now lets try to add a few bulk users
      assert SubversionRepository.set_bulk_permissions(@repository_names, {"test_user" => Repository::Permission::READ})
      assert SubversionRepository.set_bulk_permissions(@repository_names, {"test_user2" => Repository::Permission::READ_WRITE})

      # Test to make sure they got attached to each repository
      @repository_names.each do |repo_name|
        repo = Repository.get_class("svn", @conf_admin).open(SVN_TEST_REPOS_DIR + "/" + repo_name)
        assert_equal(Repository::Permission::READ, repo.get_permissions("test_user"))
        assert_equal(Repository::Permission::READ_WRITE, repo.get_permissions("test_user2"))
        repo.close()
      end

      # Ok, now let's try to remove them
      assert SubversionRepository.delete_bulk_permissions(@repository_names, ['test_user'])

      # Test to make sure they got attached to each repository
      @repository_names.each do |repo_name|
        repo = Repository.get_class("svn", @conf_admin).open(SVN_TEST_REPOS_DIR + "/" + repo_name)
        assert_raises Repository::UserNotFound do
          repo.get_permissions("test_user")
        end
        assert_equal(Repository::Permission::READ_WRITE, repo.get_permissions("test_user2"))
        repo.close()
      end
      @repositories.each do|repo|
        repo.close()
      end
    end
  end#end context

  private # private helper methods for this class

  def add_file_helper(repo, file)
    txn = repo.get_transaction(TEST_USER)
    file_contents = File.read(RESOURCE_DIR + "/" + file)
    txn.add(file, file_contents)
    repo.commit(txn)
  end

  def add_some_files_helper(repo, files)
    txn = repo.get_transaction(TEST_USER)
    files.each do |file|
      txn.add(file, File.read(RESOURCE_DIR + "/" + file))
    end
    repo.commit(txn)
  end

end # end class SubversionRepositoryTest

# Test suite for testing proper functioning of
# SubversionRevision, an implementation of AbstractRevision

#class SubversionRevisionTest < Test::Unit::TestCase
  # TODO: Test SubversionRevision here
#end
