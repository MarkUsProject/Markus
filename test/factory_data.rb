# this file will be required and its methods will be called at roughly the same time when test data in fixtures are loaded
require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/blueprints/helper'

def setup_group_fixture_repos
  Group.all.each do |group|
    group.set_repo_name
    group.build_repository
  end
  Grouping.all.each do |grouping|
    grouping.create_grouping_repository_folder
  end
end