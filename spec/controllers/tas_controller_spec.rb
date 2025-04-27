describe TasController do
  let(:instructor) { create(:instructor, user: create(:end_user, user_name: :instructor)) }
  let(:course) { instructor.course }

  describe '#upload' do
    it_behaves_like 'a controller supporting upload', formats: [:csv], background: true do
      let(:params) { { course_id: course.id } }
    end

    ['.csv', '', '.pdf'].each do |extension|
      ext_string = extension.empty? ? 'none' : extension
      it "calls perform_later on a background job on a valid CSV file with extension '#{ext_string}'" do
        expect(UploadRolesJob).to receive(:perform_later).and_return OpenStruct.new(job_id: 1)
        post_as instructor,
                :upload,
                params: { course_id: course.id,
                          upload_file: fixture_file_upload("tas/form_good#{extension}", 'text/csv') }
      end
    end

    it_behaves_like 'role is from a different course' do
      subject do
        post_as new_role,
                :upload,
                params: { course_id: course.id, upload_file: fixture_file_upload('tas/form_good.csv', 'text/csv') }
      end

      let(:role) { instructor }
    end
  end

  describe '#download' do
    subject { get_as(instructor, :download, format: format_str, params: { course_id: course.id }) }

    before { create_list(:ta, 4, course: course) }

    context 'csv' do
      let(:format_str) { 'csv' }
      let(:csv_options) { { type: 'text/csv', filename: 'ta_list.csv', disposition: 'attachment' } }

      it 'responds with appropriate status' do
        subject
        expect(response).to have_http_status(:ok)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        subject
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = course.tas.joins(:user).pluck(:user_name, :last_name, :first_name, :email).map do |data|
          data.join(',')
        end.join("\n") + "\n"
        expect(@controller).to receive(:send_data)
          .with(csv_data, csv_options) {
                                 # to prevent a 'missing template' error
                                 @controller.head :ok
                               }
        subject
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        subject
        expect(response.media_type).to eq 'text/csv'
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as(new_role, :download, format: format_str, params: { course_id: course.id })
        end

        let(:role) { instructor }
      end
    end

    context 'yml' do
      let(:yml_options) { { type: 'text/yaml', filename: 'ta_list.yml', disposition: 'attachment' } }
      let(:format_str) { 'yml' }

      it 'responds with appropriate status' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'sets disposition as attachment' do
        subject
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        output = course.tas.joins(:user).pluck_to_hash(:user_name, :last_name, :first_name, :email).to_yaml
        expect(@controller).to receive(:send_data).with(output, yml_options) { @controller.head :ok }
        subject
      end

      it 'returns text/yaml type' do
        subject
        expect(response.media_type).to eq 'text/yaml'
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as(new_role, :download, format: format_str, params: { course_id: course.id })
        end

        let(:role) { instructor }
      end
    end
  end

  describe '#create' do
    let(:params) do
      {
        role: {
          grader_permission_attributes: {
            manage_assessments: false,
            manage_submissions: true,
            run_tests: true
          },
          end_user: { user_name: end_user.user_name }
        },
        course_id: course.id
      }
    end

    context 'when a end_user exists' do
      let(:end_user) { create(:end_user) }

      context 'when the role is in the same course' do
        before { post_as instructor, :create, params: params }

        context 'When permissions are selected' do
          it 'should respond with a redirect' do
            expect(response).to redirect_to action: 'index'
          end

          it 'should create associated grader permissions' do
            ta = course.tas.where(user: end_user).first
            expect(GraderPermission.exists?(ta.grader_permission.id)).to be true
          end

          it 'should create the permissions with corresponding values' do
            ta = course.tas.where(user: end_user).first
            expect(ta.grader_permission.manage_assessments).to be false
            expect(ta.grader_permission.manage_submissions).to be true
            expect(ta.grader_permission.run_tests).to be true
          end
        end

        context 'when no permissions are selected' do
          let(:params) do
            # Rails strips empty params so a dummy value has to be given
            { course_id: course.id,
              role: { end_user: { user_name: end_user.user_name }, grader_permission_attributes: { a: 1 } } }
          end

          it 'default value for all permissions should be false' do
            ta = course.tas.where(user: end_user).first
            expect(ta.grader_permission.manage_assessments).to be false
            expect(ta.grader_permission.manage_submissions).to be false
            expect(ta.grader_permission.run_tests).to be false
          end
        end

        context 'when changing the default role' do
          let(:params) do
            {
              course_id: course.id,
              role: { end_user: { user_name: end_user.user_name }, hidden: true }
            }
          end

          it 'should change the default visibility status' do
            grader = end_user.roles.first
            expect(grader.hidden).to be(true)
          end
        end
      end

      it_behaves_like 'role is from a different course' do
        subject { post_as new_role, :create, params: params }

        let(:role) { instructor }
      end
    end

    context 'when a end_user does not exist' do
      before { post_as instructor, :create, params: params }

      let(:end_user) { build(:end_user) }

      it 'should not create a Ta' do
        expect(Ta.count).to eq(0)
      end

      it 'should display an error message' do
        expect(flash[:error]).not_to be_empty
      end
    end
  end

  describe '#index' do
    it 'respond with success on index' do
      get_as instructor, :index, params: { course_id: course.id }
      expect(response).to have_http_status(:ok)
    end

    it 'retrieves correct data' do
      get_as instructor, :index, format: 'json', params: { course_id: course.id }
      response_data = response.parsed_body['data']
      expected_data = course.tas.joins(:user)
                            .pluck_to_hash(:id, :user_name, :first_name,
                                           :last_name, :email, :hidden).as_json
      expect(response_data).to eq(expected_data)
    end

    it 'retrieves correct hidden count' do
      get_as instructor, :index, format: 'json', params: { course_id: course.id }
      response_data = response.parsed_body['counts']
      expected_data = {
        all: course.tas.size,
        active: course.tas.active.size,
        inactive: course.tas.inactive.size
      }.as_json
      expect(response_data).to eq(expected_data)
    end
  end

  describe '#update' do
    subject { post_as grader, :update, params: params }

    let(:grader) { create(:ta, course: course) }

    context 'when updating user visibility' do
      let(:new_end_user) { create(:end_user) }

      context 'as an instructor' do
        let(:params) do
          {
            course_id: course.id,
            id: grader.id,
            role: { end_user: { user_name: grader.user_name }, hidden: true }
          }
        end

        it 'should update the user' do
          post_as instructor, :update, params: params
          expect(grader.reload.hidden).to be(true)
        end
      end

      context 'as a grader' do
        let(:params) do
          {
            course_id: course.id,
            id: grader.id,
            role: { end_user: { user_name: grader.user_name }, hidden: true }
          }
        end

        it 'should not update the user' do
          subject
          expect(grader.reload.hidden).to be(false)
        end
      end
    end
  end

  describe '#destroy' do
    context 'when not an instructor' do
      let(:instructor) { create(:instructor) }
      let(:ta) { create(:ta, course: course) }
      let(:student_role) { create(:student) }

      before do
        delete_as student_role, :destroy, params: { course_id: course.id, id: ta.id }
      end

      it 'does not delete TA and gets 403 response' do
        expect(Ta.count).to eq(1)
        expect(flash.now[:success]).to be_nil
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when current_role is an instructor but destroy fails' do
      let(:instructor) { create(:instructor) }
      let(:ta) { create(:ta, course: course) }

      before do
        allow_any_instance_of(Role).to receive(:destroy).and_return(false)
        delete_as instructor, :destroy, params: { course_id: course.id, id: ta.id }
      end

      it 'does not delete the TA, shows an error message, and gets a bad request response' do
        expect(Ta.count).to eq(1)
        expect(flash.now[:success]).to be_nil
        expect(flash[:error]).to contain_message(I18n.t('flash.tas.destroy.error', user_name: ta.user_name,
                                                                                   message: ''))
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when TA has a note' do
      let(:instructor) { create(:instructor) }
      let(:ta) { create(:ta, course: course) }

      before do
        create(:note, role: ta)
        delete_as instructor, :destroy, params: { course_id: course.id, id: ta.id }
      end

      it 'does not delete the TA, shows an error message and gets a conflict response' do
        expect(Ta.count).to eq(1)
        expect(flash.now[:success]).to be_nil
        expect(flash[:error]).to contain_message(I18n.t('flash.tas.destroy.restricted', user_name: ta.user_name,
                                                                                        message: ''))
        expect(response).to have_http_status(:conflict)
      end
    end

    context 'succeeds for TA deletion' do
      let!(:ta) { create(:ta, course: course) }
      let(:instructor) { create(:instructor) }

      let!(:annotation) { create(:text_annotation, creator: ta) }

      let(:student) { create(:student) }

      before do
        create(:criterion_ta_association, ta: ta)
        create(:grade_entry_form)
        create(:grade_entry_student_ta, ta: ta, grade_entry_student: student.grade_entry_students.first)

        delete_as instructor, :destroy, params: { course_id: course.id, id: ta.id }
      end

      it 'deletes TA, flashes success, and gets an ok response' do
        expect(Ta.exists?).to be(false)
        expect(flash.now[:success]).to contain_message(I18n.t('flash.tas.destroy.success', user_name: ta.user_name))
        expect(response).to have_http_status(:no_content)
      end

      it 'deletes associated grader permisison' do
        expect(GraderPermission.exists?(role_id: ta.id)).to be(false)
      end

      it 'nullifies creator id in associated annotation' do
        annotation.reload
        expect(annotation.creator_id).to be_nil
        expect(Annotation.exists?(annotation.id)).to be(true)
      end

      it 'deletes associated criterion ta association' do
        expect(CriterionTaAssociation.exists?(ta_id: ta.id)).to be(false)
      end

      it 'deletes associated grade entry student ta' do
        expect(GradeEntryStudentTa.exists?(ta_id: ta.id)).to be(false)
      end
    end
  end
end
