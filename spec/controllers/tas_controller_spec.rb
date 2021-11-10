describe TasController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_role).and_return(build(:admin))
  end

  context '#upload' do
    include_examples 'a controller supporting upload' do
      let(:params) { {} }
    end

    it 'reports validation errors' do
      post :upload, params: {
        upload_file: fixture_file_upload('tas/form_invalid_record.csv', 'text/csv')
      }
      expect(flash[:error]).not_to be_nil
    end

    it 'does not create users when validation errors occur' do
      post :upload, params: {
        upload_file: fixture_file_upload('tas/form_invalid_record.csv', 'text/csv')
      }
      expect(Ta.all.count).to eq 0
    end

    it 'accepts a valid file' do
      post :upload, params: {
        upload_file: fixture_file_upload('tas/form_good.csv', 'text/csv')
      }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      i18t_string = [I18n.t('upload_success', count: 2)].map { |f| extract_text f }
      expect(flash[:success].map { |f| extract_text f }).to eq(i18t_string)
      expect(response).to redirect_to action: 'index'

      ta = Ta.find_by(user_name: 'c6conley')
      expect(ta.first_name).to eq('Mike')
      expect(ta.last_name).to eq('Conley')
      expect(ta.email).to eq('mike@gmail.com')
      ta = Ta.find_by(user_name: 'c8rada')
      expect(ta.first_name).to eq('Markus')
      expect(ta.last_name).to eq('Rada')
      expect(ta.email).to eq('markus@gmail.com')
    end

    it 'does not accept files with invalid columns' do
      post :upload, params: {
        upload_file: fixture_file_upload('tas/form_invalid_column.csv', 'text/csv')
      }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'

      expect(Ta.where(first_name: 'Mike')).to be_empty

      # The valid row is still used to create a new TA.
      ta = Ta.find_by(user_name: 'c8rada')
      expect(ta.first_name).to eq('Markus')
      expect(ta.last_name).to eq('Rada')
      expect(ta.email).to eq('markus@gmail.com')
    end
  end

  context '#download' do
    context 'csv' do
      let(:csv_options) do
        {
          type: 'text/csv',
          filename: 'ta_list.csv',
          disposition: 'attachment'
        }
      end

      before :each do
        4.times do
          create(:ta)
        end
        @tas = Ta.order(:user_name)
      end

      it 'responds with appropriate status' do
        get :download, format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = ''
        @tas.pluck(:user_name, :last_name, :first_name, :email).each do |ta|
          csv_data.concat("#{ta.join(',')}\n")
        end
        expect(@controller).to receive(:send_data)
                                 .with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get :download, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download, format: 'csv'
        expect(response.media_type).to eq 'text/csv'
      end
    end
    context 'yml' do
      let(:yml_options) do
        {
          type: 'text/yaml',
          filename: 'ta_list.yml',
          disposition: 'attachment'
        }
      end
      before :each do
        # create some test tas
        4.times do
          create(:ta)
        end
        @tas = Ta.order(:user_name)
      end

      it 'responds with appropriate status' do
        get :download, format: 'yml'
        expect(response.status).to eq(200)
      end

      it 'sets disposition as attachment' do
        get :download, format: 'yml'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        output = []

        @tas.all.each do |ta|
          output.push(user_name: ta.user_name, last_name: ta.last_name, first_name: ta.first_name, email: ta.email)
        end
        output = output.to_yaml
        expect(@controller).to receive(:send_data).with(output, yml_options) { @controller.head :ok }
        get :download, format: 'yml'
      end

      it 'returns text/yaml type' do
        get :download, format: 'yml'
        expect(response.media_type).to eq 'text/yaml'
      end
    end
  end

  context '#create' do
    let(:params) do
      {
        user: {
          grader_permission_attributes: {
            manage_assessments: false,
            manage_submissions: true,
            run_tests: true
          },
          user_name: 'Test',
          first_name: 'Markus',
          last_name: 'Test'
        }
      }
    end
    context 'When permissions are selected' do
      before :each do
        post :create, params: params
      end
      it 'should respond with 302' do
        expect(response).to have_http_status 302
      end
      it 'should create associated grader permissions' do
        ta = Ta.find_by(user_name: 'Test')
        expect(GraderPermission.exists?(ta.grader_permission.id)).to be true
      end
      it 'should create the permissions with corresponding values' do
        ta = Ta.find_by(user_name: 'Test')
        expect(ta.grader_permission.manage_assessments).to be false
        expect(ta.grader_permission.manage_submissions).to be true
        expect(ta.grader_permission.run_tests).to be true
      end
    end

    context 'when no permissions are selected' do
      let(:user_params) do
        {
          user: {
            user_name: 'c6conley',
            first_name: 'Mike',
            last_name: 'Conley'
          }
        }
      end
      it 'default value for all permissions should be false' do
        post :create, params: user_params
        ta = Ta.find_by(user_name: 'c6conley')
        expect(ta.grader_permission.manage_assessments).to be false
        expect(ta.grader_permission.manage_submissions).to be false
        expect(ta.grader_permission.run_tests).to be false
      end
    end
  end

  context '#update' do
    let(:ta) { create(:ta, user_name: 'c6conley', first_name: 'Mike', manage_assessments: false, run_tests: true) }
    context 'Update grader details and grader permissions' do
      before :each do
        put :update, params: { id: ta.id,
                               user: {
                                 first_name: 'Jack',
                                 grader_permission_attributes: {
                                   manage_assessments: true,
                                   run_tests: false
                                 }
                               } }
        ta.reload
      end
      it 'should respond with 302' do
        expect(response).to have_http_status 302
      end
      it 'should update the grader details' do
        expect(ta.first_name).to eq('Jack')
      end
      it 'should update the grader permissions' do
        expect(ta.grader_permission.manage_assessments).to be true
        expect(ta.grader_permission.run_tests).to be false
      end
    end
  end
end
