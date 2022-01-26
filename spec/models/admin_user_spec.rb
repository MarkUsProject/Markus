describe AdminUser do
  describe '.find_or_create' do
    let(:admin_user) { AdminUser.find_or_create }
    it 'returns an instance of AdminUser' do
      expect(admin_user).to be_an_instance_of(AdminUser)
    end
    it 'ensures the returned AdminUser api_key is not null' do
      expect(admin_user.api_key).not_to be(nil)
    end
    context 'when there is no existing AdminUser' do
      it 'will create a new AdminUser' do
        expect { AdminUser.find_or_create }.to change { AdminUser.count }.by(1)
      end
      it 'will set first_name and last_name to the default values' do
        expect(admin_user.first_name).to eq('admin')
        expect(admin_user.last_name).to eq('admin')
      end
    end
    context 'when there is existing AdminUser' do
      let!(:existing_admin_user) do
        AdminUser.create(user_name: AdminUser::ADMIN_USERNAME, first_name: 'jerry', last_name: 'foo')
      end
      let(:returned_user) { AdminUser.find_or_create }
      it 'will not create a new AdminUser' do
        expect { AdminUser.find_or_create }.not_to(change { AdminUser.count })
      end
      it 'will return the existing AdminUser' do
        expect(returned_user).to eq(existing_admin_user)
      end
      it 'will leave first_name and last_name unchanged' do
        expect(returned_user.first_name).to eq('jerry')
        expect(returned_user.last_name).to eq('foo')
      end
    end
  end
end
