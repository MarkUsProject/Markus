describe TasController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  context 'CSV_Uploads' do
    it 'accepts a valid file' do
      @file_good = fixture_file_upload('files/tas/form_good.csv', 'text/csv')
      post :upload_ta_list, params: { userlist: @file_good }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      i18t_string = [I18n.t('upload_success', count: 2)].map { |f| extract_text f }
      expect(flash[:success].map { |f| extract_text f }).to eq(i18t_string)
      expect(response).to redirect_to action: 'index'

      ta = Ta.where(user_name: 'c6conley')
      expect(ta.take['first_name']).to eq('Mike')
      expect(ta.take['last_name']).to eq('Conley')
      ta = Ta.where(user_name: 'c8rada')
      expect(ta.take['first_name']).to eq('Markus')
      expect(ta.take['last_name']).to eq('Rada')
    end

    it 'does not accept files with invalid columns' do
      @file_invalid_column = fixture_file_upload('files/tas/form_invalid_column.csv', 'text/csv')
      post :upload_ta_list, params: { userlist: @file_invalid_column }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
      expect(Ta.all.size).to be == 1
      expect(Ta.where(first_name: 'Mike')).to be_empty
    end

    it 'does not accept fileless submission' do
      post :upload_ta_list

      expect(response.status).to eq(302)
      expect(response).to redirect_to action: 'index'
    end

    it 'does not check the validity of an username' do
      @invalid_user_name = fixture_file_upload('files/tas/grader_with_invalid_username.csv', 'text/csv')
      post :upload_ta_list, params: { userlist: @invalid_user_name }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(Ta.all.size).to be == 2
      valid_ta = Ta.where(user_name: 'user123')
      expect(valid_ta.take['first_name']).to eq('Jack')
      expect(valid_ta.take['last_name']).to eq('Wood')
      # users should have the same username length
      # valid_ta has username of 6 characters
      # invalid_ta has username of 5 characters
      invalid_ta = Ta.where(user_name: 'user12')
      expect(invalid_ta.take['first_name']).to eq('James')
      expect(invalid_ta.take['last_name']).to eq('Wood')
    end

    it "does not upload grader's email address" do
      @with_emails = fixture_file_upload('files/tas/grader_with_email.csv', 'text/csv')
      post :upload_ta_list, params: { userlist: @with_emails }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(Ta.all.size).to be == 2
      ta1 = Ta.where(user_name: 'user123')
      expect(ta1.take['email']).to be_nil
      ta2 = Ta.where(user_name: 'user124')
      expect(ta2.take['email']).to be_nil
    end

    it 'does not accept a non-csv file with .csv extension' do
      @file_bad_csv = fixture_file_upload('files/bad_csv.csv', 'text/xls')
      post :upload_ta_list, params: { userlist: @file_bad_csv }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
    end

    it 'does not accept a .xls file' do
      @file_wrong_format = fixture_file_upload('files/wrong_csv_format.xls', 'text/xls')
      post :upload_ta_list, params: { userlist: @file_wrong_format }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
      expect(flash[:error].map { |f| extract_text f })
        .to eq([I18n.t('upload_errors.malformed_csv')].map { |f| extract_text f })
    end
  end

  context 'download_ta_list' do
    context 'csv' do
      let(:csv_options) do
        {
          type: 'text/csv',
          filename: 'ta_list.csv',
          disposition: 'attachment'
        }
      end

      before :each do
        # create some test tas
        (0..4).each do
          create(:ta)
        end
        @tas = Ta.order(:user_name)
      end

      it 'responds with appropriate status' do
        get :download_ta_list, format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download_ta_list, format: 'csv'
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
        get :download_ta_list, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download_ta_list, format: 'csv'
        expect(response.content_type).to eq 'text/csv'
      end
    end
  end
end
