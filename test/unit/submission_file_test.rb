require 'test_helper'
require 'shoulda'

class SubmissionFileTest < ActiveSupport::TestCase
  fixtures :assignments

  def setup
    setup_group_fixture_repos
  end

  def teardown
    destroy_repos
  end
end
