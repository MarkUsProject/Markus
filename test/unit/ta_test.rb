require File.dirname(__FILE__) + '/../test_helper'
require "shoulda"

include MarkusConfigurator

class TATest < ActiveSupport::TestCase
  fixtures :all

  def setup
    setup_group_fixture_repos
  end

  def teardown
    destroy_repos
  end

  # Update tests ---------------------------------------------------------

  # These tests are for the CSV/YML upload functions.  They're testing
  # to make sure we can easily create/update users based on their user_name

  # Test if user with a unique user number has been added to database
  def test_ta_csv_upload_with_no_duplicates
    csv_file_data = "newuser1,USER1,USER1
newuser2,USER2,USER2"
    num_users = Ta.all.size
    Ta.upload_user_list(Ta, csv_file_data)

    assert_equal num_users + 2, Ta.all.size, "Expected a different number of users - the CSV upload didn't work"


    csv_1 = Ta.find_by_user_name('newuser1')
    assert_not_nil csv_1, "Couldn't find a user uploaded by CSV"
    assert_equal "USER1", csv_1.last_name, "Last name did not match"
    assert_equal "USER1", csv_1.first_name, "First name did not match"

    csv_2 = Ta.find_by_user_name('newuser2')
    assert_not_nil csv_2, "Couldn't find a user uploaded by CSV"
    assert_equal "USER2", csv_2.last_name, "Last name did not match"
    assert_equal "USER2", csv_2.first_name, "First name did not match"

  end

  def test_ta_csv_upload_with_duplicate
    new_user = Ta.new({:user_name => "exist_user", :first_name => "Nelle", :last_name => "Varoquaux"})

    assert new_user.save, "Could not create a new User"

    csv_file_data = "newuser1,USER1,USER1
exist_user,USER2,USER2"

    User.upload_user_list(Ta, csv_file_data)

    user = Ta.find_by_user_name("exist_user")
    assert_equal "USER2", user.last_name, "Last name was not properly overwritten by CSV file"
    assert_equal "USER2", user.first_name, "First name was not properly overwritten by CSV file"

    other_user = Ta.find_by_user_name("newuser1")
    assert_not_nil other_user, "Could not find the other user uploaded by CSV"

  end

  def test_get_memberships_for_assignment
    a = assignments(:assignment_1)
    ta = users(:ta1)
    assert_not_nil ta.memberships_for_assignment(a.id)
  end

  def test_is_assigned_to_grouping
    ta = users(:ta1)
    g = groupings(:grouping_2)
    assert ta.is_assigned_to_grouping?(g.id)
  end

  context "If repo admin" do

    setup do
      setup_group_fixture_repos
      conf = Hash.new
      conf["IS_REPOSITORY_ADMIN"] = true
      conf["REPOSITORY_PERMISSION_FILE"] = MarkusConfigurator.markus_config_repository_permission_file
      @repo = Repository.get_class(markus_config_repository_type, conf)
      MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(true)
    end

    teardown do
      destroy_repos
    end

    should "grant repository_permissions when TA is added" do
      ta = Ta.new
      ta.user_name = "just_another_admin"
      ta.last_name = "doe"
      ta.first_name = "john"

      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:set_bulk_permissions).times(1).with(repo_names, {ta.user_name => Repository::Permission::READ_WRITE})
      assert = ta.save
    end

    should "revoke repository permissions when destroying an TA object" do
      ta = users(:ta1)
      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:delete_bulk_permissions).times(1).with(repo_names, [ta.user_name])
      ta.destroy
    end

  end # end context

  context "If not repository admin" do

    setup do
      setup_group_fixture_repos
      # set repository_admin false
      conf = Hash.new
      conf["IS_REPOSITORY_ADMIN"] = false
      conf["REPOSITORY_PERMISSION_FILE"] = MarkusConfigurator.markus_config_repository_permission_file
      @repo = Repository.get_class(markus_config_repository_type, conf)
      MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(false)
    end

    teardown do
      destroy_repos
    end

    should "not remove repository permissions when deleting an TA" do
      ta = users(:ta1)
      @repo.expects(:delete_bulk_permissions).never
      ta.destroy
    end

    should "not grant repository permissions for newly created TAs" do
      ta = Ta.new
      ta.user_name = "yet_another_admin"
      ta.last_name = "doe"
      ta.first_name = "john"

      @repo.expects(:set_bulk_permissions).never
      assert = ta.save
    end
  end

end
