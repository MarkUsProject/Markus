require 'spec_helper'

describe AssignmentsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:annotation_category) { FactoryGirl.create(:annotation_category) }
  let(:assignment) { FactoryGirl.create(:assignment) }

  context 'upload_assignment_list' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/assignments/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/assignments/form_good.csv', 'text/csv')))

      @file_invalid_column = fixture_file_upload(
        'files/assignments/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/assignments/form_invalid_column.csv',
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
      # This must line up with the second entry in the file_good
      @test_asn1 = 'ATest1'
      @test_asn2 = 'ATest2'
    end

    it 'accepts a valid file' do
      post :upload_assignment_list,
           assignment_list: @file_good,
           file_format: 'csv'

      expect(response.status).to eq(302)
      test1 = Assignment.find_by_short_identifier(@test_asn1)
      expect(test1).to_not be_nil
      test2 = Assignment.find_by_short_identifier(@test_asn2)
      expect(test2).to_not be_nil
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq([I18n.t('csv_valid_lines',
                                           valid_line_count: 2)])
      expect(response).to redirect_to(action: 'index',
                                      controller: 'assignments')
    end

    it 'does not accept files with invalid columns' do
      post :upload_assignment_list,
           assignment_list: @file_invalid_column,
           file_format: 'csv'

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      test = Assignment.find_by_short_identifier(@test_asn2)
      expect(test).to be_nil
      expect(response).to redirect_to(action: 'index',
                                      controller: 'assignments')
    end

    it 'does not accept fileless submission' do
      post :upload_assignment_list,
           file_format: 'csv'

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      controller: 'assignments')
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :upload_assignment_list,
           assignment_list: @file_bad_csv,
           file_format: 'csv'

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      controller: 'assignments')
    end

    it 'does not accept a .xls file' do
      post :upload_assignment_list,
           assignment_list: @file_wrong_format,
           file_format: 'csv'

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(flash[:error])
        .to eq([t('csv.upload.non_text_file_with_csv_extension')])
      expect(response).to redirect_to(action: 'index',
                                      controller: 'assignments')
    end
  end
end
