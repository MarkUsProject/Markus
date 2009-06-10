require 'test/unit'
require 'repository'

class RepositoryTest < Test::Unit::TestCase
  
  def initialize
    super
  end
  
  def setup
    @repo = Repository.new
  end
  
  def teardown
    FileUtils.remove_dir(TEST_REPOS, true)
  end
  
  def test_add_file
    
    
  end
  
  
end