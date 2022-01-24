describe AdminUser do
  let(:testuser) { AdminUser.find_or_create }
  it 'return type should be User' do
    expect(testuser).to be_a_kind_of(User)
  end
  it 'first_name and last_name should equal to the specified values' do
    expect(testuser.first_name).to eq('admin')
    expect(testuser.last_name).to eq('admin')
  end
end
