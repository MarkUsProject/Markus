require 'spec_helper'

describe RubricsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:assignment) { FactoryGirl.create(:assignment) }
  let(:grouping) { FactoryGirl.create(:grouping) }

  context 'CSV_Uploads' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/rubrics/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/rubrics/form_good.csv',
                    'text/csv')))

      @file_invalid_column = fixture_file_upload(
        'files/rubrics/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/rubrics/form_invalid_column.csv',
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
      post :csv_upload,
           assignment_id: assignment.id,
           csv_upload: { rubric: @file_good }

      assignment.reload
      rubric_criteria = assignment.rubric_criteria
      expect(4).to eq(rubric_criteria.size)
      expect('Algorithm Design')
        .to eq(rubric_criteria[0].rubric_criterion_name)
      expect(1).to eq(rubric_criteria[0].position)
      expect('Documentation').to eq(rubric_criteria[1].rubric_criterion_name)
      expect(2).to eq(rubric_criteria[1].position)
      expect('Testing').to eq(rubric_criteria[2].rubric_criterion_name)
      expect(3).to eq(rubric_criteria[2].position)
      expect('Correctness').to eq(rubric_criteria[3].rubric_criterion_name)
      expect(4).to eq(rubric_criteria[3].position)

      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq(I18n.t('rubric_criteria.upload.success',
                                           nb_updates: 4))
      expect(response).to redirect_to(action: 'index',
                                      controller: 'rubrics',
                                      id: assignment.id)
    end

    it 'does not accept files with invalid columns' do
      post :csv_upload,
           assignment_id: assignment.id,
           csv_upload: { rubric: @file_invalid_column }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      controller: 'rubrics',
                                      id: assignment.id)
    end

    it 'handles fileless submission' do
      post :csv_upload,
           assignment_id: assignment.id

      expect(response.status).to eq(302)
      expect(response).to redirect_to(action: 'index',
                                      controller: 'rubrics',
                                      id: assignment.id)
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :csv_upload,
           assignment_id: assignment.id,
           csv_upload: { rubric: @file_bad_csv }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      controller: 'rubrics',
                                      id: assignment.id)
    end

    it 'does not accept a .xls file' do
      post :csv_upload,
           assignment_id: assignment.id,
           csv_upload: { rubric: @file_wrong_format }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      controller: 'rubrics',
                                      id: assignment.id)
    end
  end
end
