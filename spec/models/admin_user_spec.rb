describe AdminUser do
  it 'return type should be User' do
    testuser = AdminUser.find_or_create
    expect(testuser).to be_a_kind_of(User)
  end
  context 'no existing admin' do
    it 'first_name and last_name should equal to the specified values' do
      testuser = AdminUser.find_or_create
      expect(testuser.first_name).to eq('admin')
      expect(testuser.last_name).to eq('admin')
    end
  end
  context 'existing admin' do
    it 'first_name and last_name should ot be changed for existing admin' do
      adminuser = AdminUser.create(user_name: AdminUser::ADMIN_USERNAME, first_name: 'jerry', last_name: 'foo')
      testuser = AdminUser.find_or_create
      expect(testuser.first_name).to eq('jerry')
      expect(testuser.last_name).to eq('foo')
      expect(testuser).to eq(adminuser)
    end
  end
end
