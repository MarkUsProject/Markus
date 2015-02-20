require 'spec_helper'

describe GradeEntryFormsController do

  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))

    #allow(GradeEntryForm).to receive(:find).and_return()

  end

  let(:grade_entry_form) { create(:grade_entry_form) }



  context 'CSV_Uploads' do

    before :each do
      @file_without_extension = fixture_file_upload('spec/fixtures/files/grade_entry_upload_empty_file')
      @file_wrong_format = fixture_file_upload('spec/fixtures/files/grade_entry_upload_wrong_format.xls')
      @file_bad_csv = fixture_file_upload('spec/fixtures/files/grade_entry_upload_bad_csv.csv')
      @file_good_csv = fixture_file_upload('spec/fixtures/files/grade_entry_upload_good_test.csv')
    end

   it 'does not accept an empty file' do
      post :csv_upload, { id: grade_entry_form }, { :upload => @file_without_extension }
      expect(response.status).to_not eq(200)
    end

    it 'should gracefully fail on non-csv file with .csv extension' do
      post :csv_upload, { id: grade_entry_form }, { :upload => @file_bad_csv }
      expect(response.status).to eq(302)
    end

  end











  context 'CSV_Downloads' do

    let(:csv_data) { grade_entry_form.get_csv_grades_report }
    let(:csv_options) { {filename: "#{grade_entry_form.short_identifier}_grades_report.csv", disposition: 'attachment', type: 'application/vnd.ms-excel'} }


    it 'tests that action csv_downloads returns OK' do
      get :csv_download, id: grade_entry_form
      expect(response.status).to eq(200)
    end

    it 'expects a call to send_data' do
      expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
        @controller.render nothing: true # to prevent a 'missing template' error
      }

      get :csv_download, id: grade_entry_form
    end

    it 'sets disposition as attachment' do
      get :csv_download, id: grade_entry_form
      #parse header object to check for the right disposition
    end

    it 'returns vnd.ms-excel type' do
      get :csv_download, id: grade_entry_form
      #parse header object to check for the right disposition
    end

    it 'passes naming conventions' do
      get :csv_download, id: grade_entry_form
      #parse header object to check for the right disposition
    end

  end

end
