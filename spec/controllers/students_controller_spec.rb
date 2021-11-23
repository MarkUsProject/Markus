describe StudentsController do
  let(:course) { admin.course }
  describe 'User is an admin' do
    let(:admin) { create :admin }
    let(:student) { create(:student, grace_credits: 5) }

    context '#index' do
      it 'returns correct student counts' do
        create_list(:student, 3)
        create_list(:student, 4, hidden: true)
        get_as admin, :index, params: { course_id: course.id, format: :json }

        counts = response.parsed_body['counts']
        expect(counts).to eq('all' => 7, 'active' => 3, 'inactive' => 4)
      end
      it_behaves_like 'role is from a different course' do
        let(:role) { admin }
        subject { get_as new_role, :index, params: { course_id: course.id, format: :json } }
      end
    end

    context '#upload' do
      include_examples 'a controller supporting upload', formats: [:csv], background: true do
        let(:params) { { course_id: course.id } }
      end

      it 'calls perform_later on a background job' do
        expect(UploadRolesJob).to receive(:perform_later).and_return OpenStruct.new(job_id: 1)
        post_as admin,
                :upload,
                params: { course_id: course.id, upload_file: fixture_file_upload('students/form_good.csv', 'text/csv') }
      end

      it_behaves_like 'role is from a different course' do
        let(:role) { admin }
        subject do
          post_as new_role, :upload, params: { course_id: course.id,
                                               upload_file: fixture_file_upload('students/form_good.csv', 'text/csv') }
        end
      end
    end

    describe '#delete_grace_period_deduction' do
      it 'deletes an existing grace period deduction' do
        grouping = create(:grouping_with_inviter, inviter: student)
        deduction = create(:grace_period_deduction,
                           membership: grouping.accepted_student_memberships.first,
                           deduction: 1)
        expect(student.grace_period_deductions.exists?).to be true
        delete_as admin,
                  :delete_grace_period_deduction,
                  params: { course_id: course.id, id: student.id, deduction_id: deduction.id }
        expect(grouping.grace_period_deductions.exists?).to be false
      end

      it 'raises a RecordNotFound error when given a grace period deduction that does not exist' do
        expect do
          delete_as admin,
                    :delete_grace_period_deduction,
                    params: { course_id: course.id, id: student.id, deduction_id: 100 }
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
          delete_as admin,
                    :delete_grace_period_deduction,
                    params: { course_id: course.id, id: student.id, deduction_id: deduction.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
      it_behaves_like 'role is from a different course' do
        let(:role) { admin }
        subject do
          delete_as new_role,
                    :delete_grace_period_deduction,
                    params: { course_id: course.id, id: student.id, deduction_id: 100 }
        end
      end
    end
  end
end
