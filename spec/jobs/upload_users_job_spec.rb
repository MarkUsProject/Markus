describe UploadUsersJob do
  context 'when running as a background job' do
    let(:file) { fixture_file_upload('admin/users_good.csv', 'text/csv') }
    let(:job_args) { [EndUser, File.read(file), nil] }

    it_behaves_like 'background job'
  end

  describe '#perform' do
    shared_examples 'uploading users' do
      subject { UploadUsersJob.perform_now(user_type, data, nil) }

      let(:data) { fixture_file_upload('admin/users_good.csv', 'text/csv').read }

      context 'when all users in the file do not exist' do
        it 'all valid users are created' do
          expect { subject }.to change { user_type.count }.to 4
        end

        context 'when the csv order of username and id number is switched' do
          before { stub_const('EndUser::CSV_ORDER', [:id_number, :last_name, :first_name, :user_name, :email]) }

          it 'does not create users' do
            expect { subject }.to raise_exception(RuntimeError)
            expect(user_type.count).to eq 0
          end
        end
      end

      context 'when a user in the file already exists' do
        before do
          create(:end_user,
                 user_name: 'frasid',
                 last_name: 'Fraser',
                 first_name: 'Sidney',
                 id_number: '',
                 email: 'sf@test.com')
        end

        it 'does not create additional valid users' do
          expect { subject }.to change { user_type.count }.to 4
        end

        it 'updates user that was already created' do
          subject
          updated_user = user_type.find_by(user_name: 'frasid')
          received_user_data = {
            user_name: updated_user.user_name,
            last_name: updated_user.last_name,
            first_name: updated_user.first_name,
            id_number: updated_user.id_number,
            email: updated_user.email
          }
          expected_user_data = {
            user_name: 'frasid',
            last_name: 'Fraser',
            first_name: 'Sidney',
            id_number: '1005602280',
            email: 'sidney.fraser@test.com'
          }
          expect(received_user_data).to eq(expected_user_data)
        end
      end
    end

    context 'uploading EndUsers' do
      let(:user_type) { EndUser }

      it_behaves_like 'uploading users'
    end
  end
end
