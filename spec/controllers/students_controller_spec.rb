describe StudentsController do
  describe 'User is an admin' do
    before :each do
      # Authenticate user is not timed out, and has administrator rights.
      allow(controller).to receive(:session_expired?).and_return(false)
      allow(controller).to receive(:logged_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(build(:admin))
    end

    let(:student) { create(:student, grace_credits: 5) }

    context '#upload' do
      include_examples 'a controller supporting upload' do
        let(:params) { {} }
      end
      it 'creates grade_entry_students as well' do
        create :grade_entry_form
        post :upload, params: {
          upload_file: fixture_file_upload('files/students/form_good.csv', 'text/csv')
        }
        expect(GradeEntryStudent.all.count).to eq(2)
      end

      it 'reports validation errors' do
        post :upload, params: {
          upload_file: fixture_file_upload('files/students/form_invalid_record.csv', 'text/csv')
        }
        expect(flash[:error]).not_to be_nil
      end

      it 'does not create users when validation errors occur' do
        post :upload, params: {
          upload_file: fixture_file_upload('files/students/form_invalid_record.csv', 'text/csv')
        }
        expect(Student.all.count).to be 0
      end

      it 'accepts a valid file' do
        post :upload, params: {
          upload_file: fixture_file_upload('files/students/form_good.csv', 'text/csv')
        }

        expect(response.status).to eq(302)
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to action: 'index'

        student = Student.find_by(user_name: 'c5anthei')
        expect(student.first_name).to eq('George')
        expect(student.last_name).to eq('Antheil')
        student = Student.find_by(user_name: 'c5bennet')
        expect(student.first_name).to eq('Robert Russell')
        expect(student.last_name).to eq('Bennett')
      end

      it 'does not accept files with invalid columns' do
        post :upload, params: {
          upload_file: fixture_file_upload('files/students/form_invalid_column.csv', 'text/csv')
        }

        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_empty
        expect(response).to redirect_to action: 'index'

        expect(Student.where(last_name: 'Antheil')).to be_empty
        expect(Student.where(user_name: 'c5bennet')).to be_empty
      end
    end

    describe '#delete_grace_period_deduction' do
      it 'deletes an existing grace period deduction' do
        grouping = create(:grouping_with_inviter, inviter: student)
        deduction = create(:grace_period_deduction,
                           membership: grouping.accepted_student_memberships.first,
                           deduction: 1)
        expect(student.grace_period_deductions.exists?).to be true
        delete :delete_grace_period_deduction,
               params: { id: student.id, deduction_id: deduction.id },
               xhr: true
        expect(grouping.grace_period_deductions.exists?).to be false
      end

      it 'raises a RecordNotFound error when given a grace period deduction that does not exist' do
        expect do
          delete :delete_grace_period_deduction,
                 params: { id: student.id, deduction_id: 100 }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises a RecordNotFound error when given a grace period deduction for a different student' do
        student2 = create(:student, grace_credits: 2)
        grouping2 = create(:grouping_with_inviter, inviter: student2)
        submission2 = create(:version_used_submission, grouping: grouping2)
        create(:complete_result, submission: submission2)
        deduction = create(:grace_period_deduction,
                           membership: grouping2.accepted_student_memberships.first,
                           deduction: 1)
        expect do
          delete :delete_grace_period_deduction,
                 params: { id: student.id, deduction_id: deduction.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'User is a Student' do
    include ERB::Util
    RSpec.shared_examples 'changing particular mailer settings' do
      it 'can be enabled in settings' do
        student.update!(setting => false)
        patch_as student,
                 'update_mailer_settings',
                 params: { student: { setting => true, other_setting => true } }
        student.reload
        expect(student[setting]).to be true
      end

      it 'can be disabled in settings' do
        student.update!(setting => true)
        patch_as student,
                 'update_mailer_settings',
                 params: { student: { setting => false, other_setting => true } }
        student.reload
        expect(student[setting]).to be false
      end
    end

    describe 'results released notifications' do
      # Authenticate user is not timed out, and is a student.
      let(:setting) { 'receives_results_emails' }
      let(:other_setting) { 'receives_invite_emails' }
      let(:student) { create(:student, user_name: 'c6stenha') }

      include_examples 'changing particular mailer settings'
    end

    describe 'group invite notifications' do
      # Authenticate user is not timed out, and is a student.
      let(:setting) { 'receives_invite_emails' }
      let(:other_setting) { 'receives_results_emails' }
      let(:student) { create(:student, user_name: 'c6stenha') }

      include_examples 'changing particular mailer settings'
    end
    describe 'changing any setting' do
      let(:student) { create(:student, user_name: 'c6stenha') }
      it 'redirects back to settings' do
        patch_as student,
                 'update_mailer_settings',
                 params: { 'student': { 'receives_invite_emails': false, 'receives_results_emails': true } }
        expect(response).to redirect_to(mailer_settings_students_path)
      end
    end
  end
end
