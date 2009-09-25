require File.dirname(__FILE__) + '/../test_helper' 
require 'shoulda'
require 'mocha'

class AdminTest < ActiveSupport::TestCase
  fixtures :users
  fixtures :groups

  def test_grant_repository_permissions_if_repo_admin
    
    admin = Admin.new
    admin.user_name = "just_another_admin"
    admin.last_name = "doe"
    admin.first_name = "john"

    mock_repo = mock('Repository')
    Group.any_instance.stubs(:repository_admin?).returns(true)
    Group.any_instance.stubs(:repo).returns(mock_repo)
    mock_repo.expects(:add_user).times(Group.all.size).with(admin.user_name, Repository::Permission::READ_WRITE)

    assert = admin.save
  end
  
  def test_grant_repository_permissions_if_not_repo_admin
    admin = Admin.new
    admin.user_name = "yet_another_admin"
    admin.last_name = "doe"
    admin.first_name = "john"
        
    mock_repo = mock('Repository')
    Group.any_instance.stubs(:repository_admin?).returns(false)
    Group.any_instance.stubs(:repo).returns(mock_repo)
    mock_repo.expects(:add_user).never

    assert = admin.save
  end
  
  def test_revoke_repository_permissions_if_admin
    admin = users(:olm_admin_1)

    mock_repo = mock('Repository')
    Group.any_instance.stubs(:repository_admin?).returns(true)
    Group.any_instance.stubs(:repo).returns(mock_repo)
    mock_repo.expects(:remove_user).times(Group.all.size).with(admin.user_name)

    admin.destroy
  end
  
  def test_revoke_repository_permissions_if_not_repo_admin
    admin = users(:olm_admin_1)
    
    mock_repo = mock('Repository')
    Group.any_instance.stubs(:repository_admin?).returns(false)
    Group.any_instance.stubs(:repo).returns(mock_repo)
    mock_repo.expects(:remove_user).never

    admin.destroy
  end
end
