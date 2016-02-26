require 'spec_helper'

describe TagsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:assignment) { FactoryGirl.create(:assignment) }

  context 'CSV_Uploads' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
          'files/tags/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
          File.read(fixture_file_upload(
                        'files/tags/form_good.csv',
                        'text/csv')))

      @file_invalid_column = fixture_file_upload(
          'files/tags/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
          File.read(fixture_file_upload(
                        'files/tags/form_invalid_column.csv',
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

      #set the :back redirect
      @redirect = 'index'
      request.env['HTTP_REFERER'] = @redirect
    end

    it 'accepts a valid file' do
      post :csv_upload,
           csv_tags: @file_good,
           assignment_id: assignment.id

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq(I18n.t('tags.upload.upload_success',
                                           nb_updates: 2))
      expect(response).to redirect_to @redirect

      expect(Tag.where(name: 'tag').take['description']).to eq('desc')
      expect(Tag.where(name: 'tag1').take['description']).to eq('desc1')
    end

    it 'does not accept files with invalid columns' do
      post :csv_upload,
           assignment_id: assignment.id,
           csv_tags: @file_invalid_column

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to @redirect
    end

    it 'does not accept fileless submission' do
      post :csv_upload,
           assignment_id: assignment.id

      expect(response.status).to eq(302)
      expect(response).to redirect_to @redirect
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :csv_upload,
           assignment_id: assignment.id,
           csv_tags: @file_bad_csv

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to @redirect
    end

    it 'does not accept a .xls file' do
      post :csv_upload,
           assignment_id: assignment.id,
           csv_tags: @file_wrong_format


      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(flash[:error][0]).to eq(I18n.t('csv.upload.non_text_file_with_csv_extension'))
      expect(response).to redirect_to @redirect
    end
  end
end
