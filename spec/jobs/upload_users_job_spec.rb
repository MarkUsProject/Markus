describe UploadRolesJob do
  let(:course) { create :course }

  context 'when running as a background job' do
    let(:file) { fixture_file_upload 'students/students.csv' }
    let(:job_args) { [Student, course, File.read(file), nil] }
    include_examples 'background job'
  end
  context '#perform' do
    subject { UploadRolesJob.perform_now(Ta, course, data, nil) }
    let(:data) { fixture_file_upload('tas/form_good.csv', 'text/csv').read }
    context 'when users exist' do
      before do
        create :human, user_name: :c6conley
        create :human, user_name: :c8rada
      end
      context 'and there are duplicates in the file' do
        let(:data) { fixture_file_upload('tas/form_invalid_record.csv', 'text/csv').read }
        it 'does not create tas' do
          expect { subject }.to raise_exception(RuntimeError)
          expect(Ta.count).to eq 0
        end
      end
      context 'and a user already has a role in the course' do
        before do
          create :student, human: Human.find_by_user_name(:c6conley), course: course
        end
        it 'does not create tas' do
          expect { subject }.to raise_exception(RuntimeError)
          expect(Ta.count).to eq 0
        end
      end
      context 'and neither user has a role in the course' do
        it 'creates tas' do
          expect { subject }.to change { Ta.count }.to 2
        end
      end
    end
    context 'when a user does not exist' do
      before { create :human, user_name: :c6conley }
      it 'does not create tas' do
        expect { subject }.to raise_exception(RuntimeError)
        expect(Ta.count).to eq 0
      end
    end
  end
end
