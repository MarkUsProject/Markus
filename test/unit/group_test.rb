# test using MACHINIST

require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__), '/../blueprints/helper')
require 'shoulda'

class GroupTest < ActiveSupport::TestCase
  SHOW_GENERATED_DATA = false
  SHOW_DEPENDENCY_GENERATED_DATA = true

  def setup
    clear_fixtures
  end

  should_have_many :groupings
  should_have_many :submissions, :through => :groupings
  should_have_many :assignments, :through => :groupings
  should_validate_presence_of :group_name
  should_not_allow_values_for :group_name, "group_long_name_12319302910102912010210219002", :message => "is too long"
  should_allow_values_for :group_name, "This group n. is short enough!" # exactly 30 char limit


  context "a group" do
    setup do
      @group = Group.make
    end

    should "have a unique group name" do 
      group = Group.new
      group.group_name = @group.group_name
      assert !group.save
    end

    
    should "allow access to its repository" do
      @group.access_repo do |repo|
        assert_not_nil(repo, "Cannot access repository")
        assert(!repo.closed?)
      end
    end

    context "linked to an assignment allowing web commits" do
      setup do 
        assignment = Assignment.make(:allow_web_submits => true)
        grouping = Grouping.make(:assignment_id => assignment.id, 
                                 :group_id => @group.id)
      end

      should "return false for external accessible repository" do
        assert !@group.repository_external_commits_only?
      end
    end

    context "linked to an assignment not allowing web commits" do
      setup do 
        assignment = Assignment.make(:allow_web_submits => false)
        grouping = Grouping.make(:assignment_id => assignment.id, 
                                 :group_id => @group.id)
      end

      should "return true for external accessible repository" do
        assert @group.repository_external_commits_only?
      end
    end
  end
end


