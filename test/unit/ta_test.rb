require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

include MarkusConfigurator

class TATest < ActiveSupport::TestCase

  def teardown
    destroy_repos
  end

  # Update tests ---------------------------------------------------------

  # These tests are for the CSV/YML upload functions.  They're testing
  # to make sure we can easily create/update users based on their user_name

  # Test if user with a unique user number has been added to database

  context 'A ta with a membership' do
    setup do
      @assignment = Assignment.make
      @ta = Ta.make
      @grouping = Grouping.make(assignment: @assignment)
      TaMembership.make(grouping: @grouping,
                        user: @ta)
    end


    should "get TA's memberships for one assignment" do
      assert_not_nil @ta.memberships_for_assignment(@assignment)
    end

    should 'already be assigned to a grouping' do
      assert @ta.is_assigned_to_grouping?(@grouping.id)
    end
  end

  context 'If repo admin' do

    setup do
      @repo = Repository.get_class
      MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(true)
    end

    should 'grant repository_permissions when TA is added' do
      ta = Ta.new
      ta.user_name = 'just_another_admin'
      ta.last_name = 'doe'
      ta.first_name = 'john'

      repo_names = Group.all.collect do |group|
                     File.join(markus_config_repository_storage, group.repository_name)
                   end
      @repo.expects(:set_bulk_permissions).times(1).with(repo_names, {ta.user_name => Repository::Permission::READ_WRITE})
      assert = ta.save
    end

    should 'revoke repository permissions when destroying a TA object' do
      ta = Ta.make
      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:delete_bulk_permissions).times(1).with(repo_names, [ta.user_name])
      ta.destroy
    end

  end # end context

  context 'If not repository admin' do

    setup do
      # set repository_admin false (NOT SURE HOW TO DO THIS NOW)
      @repo = Repository.get_class
      MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(false)
    end

    teardown do
      destroy_repos
    end

    should 'not remove repository permissions when deleting a TA' do
      ta = Ta.make
      @repo.expects(:delete_bulk_permissions).never
      ta.destroy
    end

    should 'not grant repository permissions for newly created TAs' do
      ta = Ta.new
      ta.user_name = 'yet_another_admin'
      ta.last_name = 'doe'
      ta.first_name = 'john'

      @repo.expects(:set_bulk_permissions).never
      assert = ta.save
    end
  end

end
