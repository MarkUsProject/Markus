describe TasController do
  let(:instructor) { create :instructor, user: create(:end_user, user_name: :instructor) }
  let(:course) { instructor.course }

  context '#upload' do
    include_examples 'a controller supporting upload', formats: [:csv], background: true do
      let(:params) { { course_id: course.id } }
    end

    it 'calls perform_later on a background job' do
      expect(UploadRolesJob).to receive(:perform_later).and_return OpenStruct.new(job_id: 1)
      post_as instructor,
              :upload,
              params: { course_id: course.id, upload_file: fixture_file_upload('tas/form_good.csv', 'text/csv') }
    end
    it_behaves_like 'role is from a different course' do
      let(:role) { instructor }
      subject do
        post_as new_role,
                :upload,
                params: { course_id: course.id, upload_file: fixture_file_upload('tas/form_good.csv', 'text/csv') }
      end
    end
  end

  context '#download' do
    subject { get_as(instructor, :download, format: format_str, params: { course_id: course.id }) }
    let!(:tas) { create_list :ta, 4, course: course }
    context 'csv' do
      let(:format_str) { 'csv' }
      let(:csv_options) { { type: 'text/csv', filename: 'ta_list.csv', disposition: 'attachment' } }

      it 'responds with appropriate status' do
        subject
        expect(response.status).to eq(200)
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
        let(:role) { instructor }
        subject do
          get_as(new_role, :download, format: format_str, params: { course_id: course.id })
        end
      end
    end
    context 'yml' do
      let(:yml_options) { { type: 'text/yaml', filename: 'ta_list.yml', disposition: 'attachment' } }
      let(:format_str) { 'yml' }
      it 'responds with appropriate status' do
        subject
        expect(response.status).to eq(200)
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
        let(:role) { instructor }
        subject do
          get_as(new_role, :download, format: format_str, params: { course_id: course.id })
        end
      end
    end
  end

  context '#create' do
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
      let(:end_user) { create :end_user }
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
            expect(grader.hidden).to eq(true)
          end
        end
      end
      it_behaves_like 'role is from a different course' do
        let(:role) { instructor }
        subject { post_as new_role, :create, params: params }
      end
    end
    context 'when a end_user does not exist' do
      before { post_as instructor, :create, params: params }
      let(:end_user) { build :end_user }
      it 'should not create a Ta' do
        expect(Ta.count).to eq(0)
      end
      it 'should display an error message' do
        expect(flash[:error]).not_to be_empty
      end
    end
  end

  context '#index' do
    it 'respond with success on index' do
      get_as instructor, :index, params: { course_id: course.id }
      expect(response.status).to eq(200)
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

  context '#update' do
    let(:grader) { create(:ta, course: course) }
    subject { post_as grader, :update, params: params }
    context 'when updating user visibility' do
      let(:new_end_user) { create :end_user }
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
          expect(grader.reload.hidden).to eq(true)
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
          expect(grader.reload.hidden).to eq(false)
        end
      end
    end
  end
end
