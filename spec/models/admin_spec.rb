require 'spec_helper'

describe Admin do
  context 'If repo admin' do

    before(:each) do
      @repo = Repository.get_class(markus_config_repository_type)
      MarkusConfigurator.stubs(:markus_config_repository_admin?).returns(true)
    end

    teardown do
      destroy_repos
    end

    it 'grant repository_permissions when admin is added' do
      admin = Admin.new
      admin.user_name = 'just_another_admin'
      admin.last_name = 'doe'
      admin.first_name = 'john'

      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:set_bulk_permissions).times(1).with(repo_names, {admin.user_name => Repository::Permission::READ_WRITE})
      expect(admin.save).to be true
    end

    it 'revoke repository permissions when destroying an admin object' do
      admin = FactoryGirl.create(:admin)
      repo_names = Group.all.collect do |group| File.join(markus_config_repository_storage, group.repository_name) end
      @repo.expects(:delete_bulk_permissions).times(1).with(repo_names, [admin.user_name])
      expect{admin.destroy}.to change {Admin.count}.by(-1)
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
