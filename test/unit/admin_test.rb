require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

include MarkusConfigurator
class AdminTest < ActiveSupport::TestCase
  context 'If repo admin' do

    setup do
            @repo = Repository.get_class(markus_config_repository_type)
      MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(true)
    end

    teardown do
      destroy_repos
    end

    should 'grant repository_permissions when admin is added' do
      admin = Admin.new
      admin.user_name = 'just_another_admin'
      admin.last_name = 'doe'
      admin.first_name = 'john'

      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:set_bulk_permissions).times(1).with(repo_names, {admin.user_name => Repository::Permission::READ_WRITE})
      assert admin.save
    end

    should 'revoke repository permissions when destroying an admin object' do
      admin = Admin.make
      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:delete_bulk_permissions).times(1).with(repo_names, [admin.user_name])
      admin.destroy
    end

  end # end context

  # This test only make sense if we have external repositories, and we aren't using externally managed repos
  # right now.  This needs to be rethought with respect to Configurator settings.
  # context 'If not repository admin' do
  #
  #   setup do
  #     # set repository_admin false
  #     MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(false)
  #   end
  #
  #   teardown do
  #     destroy_repos
  #   end
  #
  #   should 'not remove repository permissions when deleting an admin' do
  #     admin = Admin.make
  #     @repo.expects(:delete_bulk_permissions).never
  #     admin.destroy
  #   end
  #
  #   should 'not grant repository permissions for newly created admins' do
  #     admin = Admin.new
  #     admin.user_name = 'yet_another_admin'
  #     admin.last_name = 'doe'
  #     admin.first_name = 'john'
  #
  #     @repo.expects(:set_bulk_permissions).never
  #     assert admin.save
  #   end
  # end

end
