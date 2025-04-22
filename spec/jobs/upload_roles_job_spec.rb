describe UploadRolesJob do
  let(:course) { create(:course) }

  context 'when running as a background job' do
    let(:file) { fixture_file_upload 'students/students.csv' }
    let(:job_args) { [Student, course, File.read(file), nil] }

    it_behaves_like 'background job'
  end

  describe '#perform' do
    shared_examples 'uploading roles' do
      subject { UploadRolesJob.perform_now(role_type, course, data, nil) }

      let(:data) { fixture_file_upload('tas/form_good.csv', 'text/csv').read }
      context 'when users exist' do
        before do
          create(:end_user, user_name: :c6conley)
          create(:end_user, user_name: :c8rada)
        end

        context 'and a user already has a role in the course' do
          before do
            create(:instructor, user: EndUser.find_by(user_name: :c6conley), course: course)
          end

          it 'does not create roles' do
            expect { subject }.to raise_exception(RuntimeError)
            expect(role_type.count).to eq 0
          end
        end

        context 'and neither user has a role in the course' do
          it 'creates roles' do
            expect { subject }.to change { role_type.count }.to 2
          end

          context 'when the user_name index does not match the uploaded file' do
            before { stub_const('Student::CSV_ORDER', [:section_id, :first_name, :last_name, :user_name]) }

            it 'does not create roles' do
              expect { subject }.not_to(change { role_type.count })
            end
          end
        end
      end

      context 'when a user does not exist' do
        before { create(:end_user, user_name: :c6conley) }

        it 'does not create tas' do
          expect { subject }.to raise_exception(RuntimeError)
          expect(role_type.count).to eq 0
        end
      end
    end

    context 'uploading TAs' do
      let(:role_type) { Ta }

      it_behaves_like 'uploading roles'
    end

    context 'uploading Students' do
      let(:role_type) { Student }

      it_behaves_like 'uploading roles'
      context 'should add students to sections' do
        subject { UploadRolesJob.perform_now(role_type, course, data, nil) }

        let(:data) { fixture_file_upload('tas/form_good.csv', 'text/csv').read }

        let(:csv_order) { %w[user_name section_name].map(&:to_sym) }

        before do
          stub_const('Student::CSV_ORDER', csv_order)
          create(:end_user, user_name: :c6conley)
          create(:end_user, user_name: :c8rada)
        end

        context 'when the section exists' do
          let!(:section) { create(:section, name: 'abc', course: course) }

          it 'should succeed if the section exists' do
            expect { subject }.to change { course.students.count }.to 2
          end

          it 'should assign students to sections' do
            expect { subject }.to change { section.students.count }.to 1
          end
        end

        context 'when the section does not exist' do
          it 'should not assign students to sections' do
            expect { subject }.to raise_exception(RuntimeError)
            expect(course.students.count).to eq(0)
          end
        end
      end
    end
  end
end
