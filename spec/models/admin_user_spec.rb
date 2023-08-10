describe AdminUser do
  describe '.find_or_create' do
    let(:admin_user) { AdminUser.find_or_create }
    it 'returns an instance of AdminUser' do
      expect(admin_user).to be_an_instance_of(AdminUser)
    end
    it 'ensures the returned AdminUser api_key is not nil' do
      expect(admin_user.api_key).not_to be(nil)
    end
    context 'when there is no existing AdminUser' do
      it 'creates a new AdminUser' do
        expect { AdminUser.find_or_create }.to change { AdminUser.count }.by(1)
      end
      it 'sets first_name to the default value' do
        expect(admin_user.first_name).to eq('admin')
      end
      it 'sets last_name to the default value' do
        expect(admin_user.last_name).to eq('user')
      end
    end
    context 'when there is existing AdminUser' do
      let!(:existing_admin_user) do
        AdminUser.create(user_name: AdminUser::ADMIN_USERNAME, first_name: 'jerry', last_name: 'foo')
      end
      it 'does not create a new AdminUser' do
        expect { AdminUser.find_or_create }.not_to(change { AdminUser.count })
      end
      it 'returns the existing AdminUser' do
        expect(admin_user).to eq(existing_admin_user)
      end
      it 'leaves first_name unchanged' do
        expect(admin_user.first_name).to eq('jerry')
      end
      it 'leaves last_name unchanged' do
        expect(admin_user.last_name).to eq('foo')
      end
    end
  end
end
