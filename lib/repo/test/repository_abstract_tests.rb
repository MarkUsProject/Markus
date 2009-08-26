require 'test/unit'
require 'time'

class RepositoryAbstractTests < Test::Unit::TestCase
  def basic_fixture
    transaction = @repo.get_transaction("someuser")
    transaction.add("SomeFile.java", "File contents", "text/java")
    @repo.commit(transaction)
    
    transaction = @repo.get_transaction("someuser")
    transaction.add("SomeNewFile.java",  "File Contents", "text/java")
    @repo.commit(transaction)
    
    transaction = @repo.get_transaction("someuser")
    transaction.add("new_folder/SomeFolderFile.java",  "File Contents", "text/java")
    @repo.commit(transaction)
  end

  def test_create
    assert_not_nil @repo, "Could not create Repository"
  end
  
  def test_number_of_revisions
    assert_equal 0, @repo.latest_revision_number, "Number of revisions is wrong"
    transaction = @repo.get_transaction("someuser")
    transaction.add("SomeFile.java", "File Contents", "text/java")
    @repo.commit(transaction)
    assert_equal 1, @repo.latest_revision_number, "Number of revisions is wrong"
  end
  
  def test_get_revision
    basic_fixture
    assert_equal 3, @repo.latest_revision_number, "Number of revisions is wrong"
    revision = @repo.get_revision(1)
    files = revision.files_at_path('/')
    assert_equal 1, files.count, "Number of files in this revision is wrong"
    file = files["SomeFile.java"]
    assert_not_nil file, "Could not find an expected file"
    assert_equal "SomeFile.java", file.name, "Name of file is wrong"
    
    revision = @repo.get_revision(2)
    files = revision.files_at_path('/')
    assert_equal 2, files.count, "Number of files in this revision is wrong"
    file = files["SomeNewFile.java"]
    assert_not_nil file, "Could not find an expected file"
    assert_equal "SomeNewFile.java", file.name, "Name of file is wrong"
  end
  
  def test_get_invalid_revision
    basic_fixture
    assert_raises Repository::RevisionDoesNotExist do
      revision = @repo.get_revision(4)
    end
    transaction = @repo.get_transaction("someuser")
    transaction.add("NewFile.java", "Some new file contents", "text/java")
    @repo.commit(transaction)
    revision = @repo.get_revision(4)
    assert_not_nil revision, "Could not find revision"
  end
  
  def test_get_missing_file
    basic_fixture
    revision = @repo.get_latest_revision
    files = revision.files_at_path('/')
    assert_nil files["MissingFile.java"], "Found a file that shouldn't be there"
  end
  
  def test_download_missing_file
    basic_fixture
    file = nil
    assert_raises TypeError do
      @repo.download_as_string(file)
    end
    
    file = Repository::RevisionFile.new(1, {
      :name => 'InvalidFile.java',
      :path => '/',
      :last_modified_revision => 1,
      :changed => true,
      :user_id => 'someuser'
    })
    assert_raises Repository::FileDoesNotExistConflict do
      @repo.download_as_string(file)
    end
    
    begin
      @repo.download_as_string(file)
    rescue Repository::FileDoesNotExistConflict => e
#      assert e.attempted_job.kind_of?(Repository::RevisionFile), "Did not get the right kind of conflict - expected the attempted_job to be a file"
      assert_equal '/InvalidFile.java', e.path, "Did not get the right conflict contents - expected the missing file"
    end
    
    file = Repository::RevisionFile.new(1, {
      :name => '??>@$>Z>$@<D',
      :path => '/s35523/a4yasda/asdr43rasdf/??!....%*@#!(@)',
      :last_modified_revision => 1,
      :changed => true,
      :user_id => 'someuser'
    })
    assert_raises Repository::FileDoesNotExistConflict do
      @repo.download_as_string(file)
    end
    
    begin
      @repo.download_as_string(file)
    rescue Repository::FileDoesNotExistConflict => e
      assert_equal '/s35523/a4yasda/asdr43rasdf/??!....%*@#!(@)/??>@$>Z>$@<D', e.path, "Did not get the right conflict contents - expected the missing file"
    end

  end
  
  def test_get_missing_directory
    basic_fixture
  end
end
  
#    revision = @repo.get_revision(3)
#    assert_not_nil revision, "Could not retrieve Revision with get_revision"
#    assert_equal 3, revision.number, "Revision number did not match"
#    assert_equal "Needed to update TestShapes.java!", revision.comment, "Comments did not match"
#    assert_equal "Fri May 22 13:35:02 -0400 2009", revision.timestamp, "Timestamps did not match"
#    assert_equal "c6conley", revision.user_id, "User ID did not match"
#    
#    assert_raises Repository::RevisionDoesNotExist do
#      revision = @repo.get_revision(50)
#    end


#  end

#  def test_get_revision_by_timestamp
#    revision = @repo.get_revision_by_timestamp(Time.parse("Wed May 20 13:35:02 -0400 2009"))
#    assert_not_nil revision, "Could not retrieve Revision with get_revision_by_timestamp"
#    assert_equal 1, revision.number, "Revision number did not match"
#    assert_equal "This was my first commit!", revision.comment, "Comments did not match"
#    assert_equal "Wed May 20 13:35:02 -0400 2009", revision.timestamp, "Timestamps did not match"
#    assert_equal "c6conley", revision.user_id, "User ID did not match"


#    assert_raises Repository::RevisionDoesNotExist do
#      revision = @repo.get_revision_by_timestamp(Time.parse("Mon May 18 14:35:02 -0400 2009"))    
#    end

#    
#    revision = @repo.get_revision_by_timestamp(Time.parse("Thu May 21 13:35:02 -0400 2009"))
#    assert_not_nil revision, "Could not retrieve Revision with get_revision_by_timestamp"
#    assert_equal 2, revision.number, "Revision number did not match"
#    assert_equal "Whoops - needed to add TestShapes.java", revision.comment, "Comments did not match"
#    assert_equal "Thu May 21 13:35:02 -0400 2009", revision.timestamp, "Timestamps did not match"
#    assert_equal "c6conley", revision.user_id, "User ID did not match"


#    
#    revision = @repo.get_revision_by_timestamp(Time.parse("Sun May 24 14:35:02 -0400 2009"))
#    assert_not_nil revision, "Could not retrieve Revision with get_revision_by_timestamp"
#    assert_equal 3, revision.number, "Revision number did not match"
#    assert_equal "Needed to update TestShapes.java!", revision.comment, "Comments did not match"
#    assert_equal "Fri May 22 13:35:02 -0400 2009", revision.timestamp, "Timestamps did not match"
#    assert_equal "c6conley", revision.user_id, "User ID did not match"

#  end  
#  
#  def test_get_files_in_revision
#    revision = @repo.get_revision(0)
#    files = revision.all_files
#    assert_equal true, files.empty?, "Returned a revision with files when not expected"
#    
#    revision = @repo.get_revision(1)

#    file = revision.all_files["Test.java"]
#    assert_equal "Test.java", file.name, "Did not receive the right file"
#    assert_equal 1, file.last_modified_revision, "Did not receive the right file"
#    
#    revision = @repo.get_revision(2)
#    
#    file = revision.all_files["Test.java"]
#    assert_equal "Test.java", file.name, "Did not receive the right file"
#    assert_equal 1, file.last_modified_revision, "Did not receive the right file"
#    
#    file = revision.all_files["TestShapes.java"]
#    assert_equal "TestShapes.java", file.name, "Did not receive the right file"
#    assert_equal 2, file.last_modified_revision, "Did not receive the right file"
#        
#  end
#  
#  def test_get_changed_files
#    revision = @repo.get_revision(2)
#    
#    assert_equal 1, revision.changed_files.count, "Did not get the right number of changed files"
#    
#    file = revision.changed_files["TestShapes.java"]
#    
#    assert_equal "TestShapes.java", file.name, "Did not receive the right file"
#    assert_equal 2, file.last_modified_revision, "Did not receive the right file"

#  end
#  
#  def test_download
#    revision = @repo.get_revision(2)
#    target_file = revision.all_files["TestShapes.java"]
#    result_string = @repo.download(target_file)
#    
#    assert_equal "This is some NEW TestShapes.java file!", result_string, "Did not receive the correct file contents"
#    
#    target_file = revision.all_files["Test.java"]
#    result_string = @repo.download(target_file)
#    assert_equal "This is some Test.java file!", result_string, "Did not receive the correct file contents"

#  end
#  
#  def test_add_file_commit
#   
#    @repo.add_file("NewFile.java", "This is some new content!")
#    @repo.commit
#    
#    assert_equal 4, @repo.number_of_revisions, "Number of revisions is wrong"
#    
#    revision = @repo.get_latest_revision
#    target_file = revision.all_files["NewFile.java"]
#    result_string = @repo.download(target_file)
#    assert_equal "This is some new content!", result_string, "Did not receive the correct file contents"
#    
#  end
#  
#  def test_add_file_conflict
#    @repo.add_file("Test.java", "This shouldn't get added")
#    assert_raises Repository::CommitConflicts do
#      @repo.commit
#    end
#    
#    @repo.add_file("Test.java", "This shouldn't get added")
#    begin
#      @repo.commit
#    rescue Repository::CommitConflicts => commit_conflicts
#      conflicts = commit_conflicts.get_conflicts
#      assert_equal 1, conflicts.length, "Expected only 1 conflict"
#      assert_instance_of Repository::FileExistsConflict, conflicts[0], "Got the wrong type of conflict"
#    end
#  end
#  
#  def test_remove_file_commit
#    @repo.remove_file("Test.java")
#    @repo.commit
#    assert_equal 4, @repo.number_of_revisions, "Number of revisions is wrong"    
#    revision = @repo.get_latest_revision
#    assert_nil revision.all_files["Test.java"], "File still existed"
#    assert_equal "TestShapes.java", revision.all_files["TestShapes.java"].name, "A file that we expected to exist, doesn't exist anymore."
#  end
#  
#  def test_replace_file_commit
#    @repo.replace_file("Test.java", "Here is some brand new content!", 1)
#    @repo.commit
#    assert_equal 4, @repo.number_of_revisions, "Number of revisions is wrong"
#    revision = @repo.get_latest_revision
#    target_file = revision.all_files["Test.java"]
#    result_string = @repo.download(target_file)
#    assert_equal "Here is some brand new content!", result_string, "Did not receive the correct file contents"
#       
#  end
#  
#  def test_replace_file_commit_with_conflict

#    @repo.replace_file("TestShapes.java", "This should not get written", 2)
#    begin
#      @repo.commit
#    rescue Repository::CommitConflicts => commit_conflicts
#      conflicts = commit_conflicts.get_conflicts
#      assert_equal 1, conflicts.length, "Expected only 1 conflict"
#      assert_instance_of Repository::RevisionOutOfSyncConflict, conflicts[0], "Got the wrong type of conflict"
#    end
#    
#    # Make sure it wasn't written    
#    assert_equal 3, @repo.number_of_revisions, "Number of revisions is wrong"
#    revision = @repo.get_latest_revision
#    target_file = revision.all_files["TestShapes.java"]
#    result_string = @repo.download(target_file)
#    assert_equal "This is some ALTERED Test.java file!", result_string, "Did not receive the correct file contents"
#  
#  end
#  
#  def add_file_get_changes
#    @repo.add_file("NewFile.java", "A brand new file!")
#    @repo.commit   
#    revision = @repo.get_latest_revision
#    assert_equal 1, revision.changed_files.length, "Did not get the right number of changed files"   
#    file = revision.changed_files["NewFile.java"]
#    assert_equal "NewFile.java", file.name, "Did not receive the right file"
#    assert_equal 4, file.last_modified_revision, "Did not receive the right file"
#  end
#  
#  def test_get_users
#    users = @repo.get_users
#    assert_equal ["c6conley"], users, "Users do not match"
#  end
#  
#  def test_add_user
#    @repo.add_user("c6smith")
#    assert_equal ["c6conley", "c6smith"], @repo.get_users, "Users do not match"
#  end
#  
#  def test_remove_user
#    @repo.add_user("c6smith")
#    @repo.remove_user("c6conley")
#    assert_equal ["c6smith"], @repo.get_users, "Users do not match"
#  end
