describe StudentsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:course) { instructor.course }

  describe 'User is an instructor' do
    let(:instructor) { create(:instructor) }
    let(:student) { create(:student, grace_credits: 5) }

    describe '#index' do
      it 'returns correct student counts' do
        create_list(:student, 3)
        create_list(:student, 4, hidden: true)
        get_as instructor, :index, params: { course_id: course.id, format: :json }

        counts = response.parsed_body['counts']
        expect(counts).to eq('all' => 7, 'active' => 3, 'inactive' => 4)
      end

      it_behaves_like 'role is from a different course' do
        subject { get_as new_role, :index, params: { course_id: course.id, format: :json } }

        let(:role) { instructor }
      end
    end

    describe '#update' do
      let(:section) { create(:section, { course_id: course.id }) }
      let(:params) do
        {
          role: { end_user: { user_name: student.user_name }, id: student.id, hidden: !student.hidden,
                  section_id: section.id, grace_credits: student.grace_credits + 1 },
          course_id: course.id,
          id: student.id
        }
      end

      it 'updates the student with the right attributes' do
        patch_as instructor, :update, params: params
        expected = params[:role].slice(:hidden, :section_id, :grace_credits).stringify_keys
        expect(student.reload.attributes.slice('hidden', 'section_id', 'grace_credits')).to eq expected
      end
    end

    describe '#upload' do
      it_behaves_like 'a controller supporting upload', formats: [:csv], background: true do
        let(:params) { { course_id: course.id } }
      end

      ['.csv', '', '.pdf'].each do |extension|
        ext_string = extension.empty? ? 'none' : extension
        it "calls perform_later on a background job on a valid file with extension '#{ext_string}'" do
          file = fixture_file_upload("students/form_good#{extension}", 'text/csv')
          expect(UploadRolesJob).to receive(:perform_later).and_return OpenStruct.new(job_id: 1)
          post_as instructor,
                  :upload,
                  params: { course_id: course.id, upload_file: file }
        end
      end

      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :upload, params: { course_id: course.id,
                                               upload_file: fixture_file_upload('students/form_good.csv', 'text/csv') }
        end

        let(:role) { instructor }
      end
    end

    describe '#bulk_modify' do
      let(:section) { create(:section, { course_id: course.id }) }
      let(:shared_params) { { student_ids: students.map(&:id), course_id: course.id } }

      context 'when the action is update_section' do
        let(:students) { create_list(:student, 3, section_id: section.id) }

        it "sets each student's section to the given section" do
          patch_as instructor, :bulk_modify,
                   params: shared_params.merge({ bulk_action: 'update_section', section: nil })
          students.each do |student|
            student.reload
            expect(student.section).to be_nil
          end
        end
      end

      context 'when the action is hide' do
        let(:students) { create_list(:student, 3, hidden: false) }

        it "sets each student's status to inactive" do
          patch_as instructor, :bulk_modify, params: shared_params.merge({ bulk_action: 'hide' })
          students.each do |student|
            student.reload
            expect(student.hidden).to be(true)
          end
        end
      end

      context 'when the action is unhide' do
        let(:students) { create_list(:student, 3, hidden: true) }

        it "sets each student's status to active" do
          patch_as instructor, :bulk_modify, params: shared_params.merge({ bulk_action: 'unhide' })
          students.each do |student|
            student.reload
            expect(student.hidden).to be(false)
          end
        end
      end

      context 'when the action is give_grace_credits' do
        let(:students) { create_list(:student, 3, grace_credits: 3) }

        it "adds the provided grace credits to each student's grace credits" do
          patch_as instructor, :bulk_modify,
                   params: shared_params.merge({ bulk_action: 'give_grace_credits', grace_credits: 1 })
          students.each do |student|
            student.reload
            expect(student.grace_credits).to eq(4)
          end
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
        delete_as instructor,
                  :delete_grace_period_deduction,
                  params: { course_id: course.id, id: student.id, deduction_id: deduction.id }
        expect(grouping.grace_period_deductions.exists?).to be false
      end

      it 'raises a RecordNotFound error when given a grace period deduction that does not exist' do
        expect do
          delete_as instructor,
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
          delete_as instructor,
                    :delete_grace_period_deduction,
                    params: { course_id: course.id, id: student.id, deduction_id: deduction.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it_behaves_like 'role is from a different course' do
        subject do
          delete_as new_role,
                    :delete_grace_period_deduction,
                    params: { course_id: course.id, id: student.id, deduction_id: 100 }
        end

        let(:role) { instructor }
      end
    end
  end

  describe 'role is a student' do
    let(:role) { create(:student) }

    shared_examples 'changing particular mailer settings' do
      it 'can be enabled in settings' do
        role.update!(setting => false)
        patch_as role,
                 'update_settings',
                 params: { course_id: role.course.id, id: role.id, role: { setting => true, other_setting => true } }
        role.reload
        expect(role[setting]).to be true
      end

      it 'can be disabled in settings' do
        role.update!(setting => true)
        patch_as role,
                 'update_settings',
                 params: { course_id: role.course.id, id: role.id, role: { setting => false, other_setting => true } }
        role.reload
        expect(role[setting]).to be false
      end

      it 'redirects back to settings' do
        patch_as role,
                 'update_settings',
                 params: { course_id: role.course.id, id: role.id, role: { setting => true, other_setting => true } }
        expect(response).to redirect_to(settings_course_students_path(role.course))
      end
    end

    describe 'results released notifications' do
      # Authenticate role is not timed out, and is a student.
      let(:setting) { 'receives_results_emails' }
      let(:other_setting) { 'receives_invite_emails' }

      it_behaves_like 'changing particular mailer settings'
    end

    describe 'group invite notifications' do
      # Authenticate role is not timed out, and is a student.
      let(:setting) { 'receives_invite_emails' }
      let(:other_setting) { 'receives_results_emails' }

      it_behaves_like 'changing particular mailer settings'
    end
  end
end
