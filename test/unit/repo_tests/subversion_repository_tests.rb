require 'test/unit'
require 'test/unit/repo_tests/repository_abstract_tests_read'
require 'lib/repo/subversion_repository'
require 'fileutils'
require "svn/repos"
class SubversionRepositoryTest < Test::Unit::TestCase
  include RepositoryAbstractTests
  
  TEST_REPO_DIR = 'test/unit/repo_tests/repositories/testrepo'
  
  def setup
    # Without using Repository::SubversionRepository, create a repository
    # somewhere to use as a test harness.
    setup_repository(TEST_REPO_DIR)
    @repo = Repository::SubversionRepository.new(TEST_REPO_DIR)
  end
  def teardown
    FileUtils.rm_rf(TEST_REPO_DIR)
  end

  def setup_repository(path=@repos_path, config={}, fs_config={})
    require "svn/repos"
    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(File.dirname(path))
    @repos = Svn::Repos.create(path, config, fs_config)
    #@fs = @repos.fs
  end

end
