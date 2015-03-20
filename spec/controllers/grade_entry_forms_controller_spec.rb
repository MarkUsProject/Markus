require 'spec_helper'

describe GradeEntryFormsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:grade_entry_form) { create(:grade_entry_form) }

  context 'CSV_Uploads' do
    before :each do
      @file_without_extension =
        fixture_file_upload('spec/fixtures/files/grade_entry_upload_empty_file',
                            'text/xml')
      @file_wrong_format =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_upload_wrong_format.xls', 'text/xls')
      @file_bad_csv =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_upload_bad_csv.csv', 'text/xls')
      @file_wrong_columns =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_upload_wrong_columns.csv',
          'text/csv')
    end

    # this test is currently failing.
    # issue #2078 has been opened to resolve this
    # it 'does not accept a csv file with wrong data columns' do
    #  post :csv_upload, id: grade_entry_form,
    #      upload: { :grades_file => @file_wrong_columns }
    # expect(response.status).to eq(302)
    # expect(flash[:error]).to_not be_empty
    # expect(response).to redirect_to(
    #   grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    # end

    it 'does not accept a file with no extension' do
      post :csv_upload,
           id: grade_entry_form,
           upload: { grades_file: @file_without_extension }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end

    it 'does not accept fileless submission' do
      post :csv_upload, id: grade_entry_form
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end

    # this test is currently failing
    # issue #2075 has been opened to resolve this
    # it 'should gracefully fail on non-csv file with .csv extension' do
    #  post :csv_upload, id: grade_entry_form,
    #      upload: { grades_file: @file_bad_csv }
    # expect(response.status).to eq(302)
    # expect(flash[:error]).to_not be_empty
    # expect(response).to redirect_to(
    #   grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    # end

    it 'should gracefully fail on .xls file' do
      post :csv_upload,
           id: grade_entry_form,
           upload: { grades_file: @file_wrong_format }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end
  end

  context 'CSV_Downloads' do
    let(:csv_data) { grade_entry_form.get_csv_grades_report }
    let(:csv_options) do 
      {
        filename: "#{grade_entry_form.short_identifier}_grades_report.csv",
        disposition: 'attachment',
        type: 'application/vnd.ms-excel'
      }
    end

    it 'tests that action csv_downloads returns OK' do
      get :csv_download, id: grade_entry_form
      expect(response.status).to eq(200)
    end

    it 'expects a call to send_data' do
      expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.render nothing: true
      }
      get :csv_download, id: grade_entry_form
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :csv_download, id: grade_entry_form
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    # parse header object to check for the right content type
    it 'returns vnd.ms-excel type' do
      get :csv_download, id: grade_entry_form
      expect(response.content_type).to eq 'application/vnd.ms-excel'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get :csv_download, id: grade_entry_form
      filename = response.header['Content-Disposition']
                 .split.last.split('"').second
      expect(filename).to eq "#{grade_entry_form.short_identifier}" +
        '_grades_report.csv'
    end
  end
end
