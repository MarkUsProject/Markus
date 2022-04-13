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
      end

      context 'when a user in the file already exists' do
        before { create :end_user, user_name: 'rosskx', last_name: 'Ross', first_name: 'Knox' }
        it 'fails to create any new users' do
          expect { subject }.to raise_exception(RuntimeError)
          expect(user_type.count).to eq 1
        end
      end
    end

    context 'uploading EndUsers' do
      let(:user_type) { EndUser }
      include_examples 'uploading users'
    end
  end
end
