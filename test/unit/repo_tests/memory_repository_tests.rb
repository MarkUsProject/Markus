require 'test/unit'
require 'test/unit/repo_tests/repository_abstract_tests'
require 'lib/repo/memory_repository'
class MemoryRepositoryTest < Test::Unit::TestCase
  include RepositoryAbstractTests

  TEST_REPO_YML = 'test/unit/repo_tests/repositories/memory.yml'
  
  def setup
    # Without using Repository::SubversionRepository, create a repository
    # somewhere to use as a test harness.
    @repo = Repository::MemoryRepository.new(TEST_REPO_YML)
  end
  def teardown
  end
end
