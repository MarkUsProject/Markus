require 'spec_helper'

describe TasController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  context 'CSV_Uploads' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/tas/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/tas/form_good.csv',
                    'text/csv')))

      @file_invalid_column = fixture_file_upload(
        'files/tas/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/tas/form_invalid_column.csv',
                    'text/csv')))

      @file_bad_csv = fixture_file_upload(
        'files/bad_csv.csv', 'text/xls')
      allow(@file_bad_csv).to receive(:read).and_return(
        File.read(fixture_file_upload('files/bad_csv.csv', 'text/csv')))

      @file_wrong_format = fixture_file_upload(
        'files/wrong_csv_format.xls', 'text/xls')
      allow(@file_wrong_format).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/wrong_csv_format.xls', 'text/csv')))
    end

    it 'accepts a valid file' do
      post :upload_ta_list,
           userlist: @file_good

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq([I18n.t('csv_valid_lines',
                                            valid_line_count: 2)])
      expect(response).to redirect_to action: 'index'

      ta = Ta.where(user_name: 'c6conley')
      expect(ta.take['first_name']).to eq('Mike')
      expect(ta.take['last_name']).to eq('Conley')
      ta = Ta.where(user_name: 'c8rada')
      expect(ta.take['first_name']).to eq('Markus')
      expect(ta.take['last_name']).to eq('Rada')
    end

    it 'does not accept files with invalid columns' do
      post :upload_ta_list,
           userlist: @file_invalid_column

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'

      expect(Ta.where(first_name: 'Mike')).to be_empty
    end

    it 'does not accept fileless submission' do
      post :upload_ta_list

      expect(response.status).to eq(302)
      expect(response).to redirect_to action: 'index'
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :upload_ta_list,
           userlist: @file_bad_csv

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
    end

    it 'does not accept a .xls file' do
      post :upload_ta_list,
           userlist: @file_wrong_format

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
      expect(flash[:error])
        .to eq([I18n.t('csv.upload.non_text_file_with_csv_extension')])
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
        get :download_ta_list,
            format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download_ta_list,
            format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = ''
        @tas.pluck(:user_name, :last_name, :first_name).each do |ta|
          csv_data.concat("#{ta.join(',')}\n")
        end
        expect(@controller).to receive(:send_data)
                                 .with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.render nothing: true
        }
        get :download_ta_list,
            format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download_ta_list,
            format: 'csv'
        expect(response.content_type).to eq 'text/csv'
      end
    end
  end
end
