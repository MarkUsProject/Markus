describe UploadUsersJob do
  context 'when running as a background job' do
    let(:file) { fixture_file_upload('admin/users_good.csv', 'text/csv') }
    let(:job_args) { [EndUser, File.read(file), nil] }
    include_examples 'background job'
  end
  context '#perform' do
    shared_examples 'uploading users' do
      subject { UploadUsersJob.perform_now(user_type, data, nil) }
      let(:data) { fixture_file_upload('admin/users_good.csv', 'text/csv').read }

      context 'when all users in the file do not exist' do
        it 'all valid users are created' do
          expect { subject }.to change { user_type.count }.to 4
        end
        it 'fails to create users with invalid information' do
          subject
          expect(EndUser.find_by(user_name: 'invalid')).to be_nil
        end
        context 'when the csv order of username and id number is switched' do
          before { stub_const('EndUser::CSV_ORDER', [:id_number, :last_name, :first_name, :user_name, :email]) }
          it 'only creates users with an id number' do
            subject
            expect(user_type.count).to eq 2
          end
          it 'changes the meaning of only username and id number row index' do
            subject
            user = EndUser.find_by(user_name: '1005602280')
            received_data = {
              user_name: user.user_name,
              last_name: user.last_name,
              first_name: user.first_name,
              id_number: user.id_number,
              email: user.email
            }
            expected_data = {
              user_name: '1005602280',
              last_name: 'Fraser',
              first_name: 'Sidney',
              id_number: 'frasid',
              email: 'sidney.fraser@test.com'
            }
            expect(received_data).to eq(expected_data)
          end
        end
      end

      context 'when a user in the file already exists' do
        before do
          create :end_user,
                 user_name: 'frasid',
                 last_name: 'Fraser',
                 first_name: 'Sidney',
                 id_number: '1005602280',
                 email: 'sidney.fraser@test.com'
        end
        it 'does not create additional valid users' do
          expect { subject }.to change { user_type.count }.to 4
        end
      end
    end

    context 'uploading EndUsers' do
      let(:user_type) { EndUser }
      include_examples 'uploading users'
    end
  end
end
