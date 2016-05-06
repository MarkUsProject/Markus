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

  context 'download_csv' do
    let(:csv_options) do
      {
        type: 'text/csv',
        filename: "#{assignment.short_identifier}_rubric_criteria.csv",
        disposition: 'attachment'
      }
    end

    before :each do
      @criterion = create(:rubric_criterion, assignment: assignment)
    end

    it 'responds with appropriate status' do
      get :download_csv,
          assignment_id: assignment.id
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :download_csv,
          assignment_id: assignment.id
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      csv_data = "#{@criterion.name},#{@criterion.weight},"
      criterion_array = []
      (0..4).each do |i|
        criterion_array.push(@criterion['level_' + i.to_s + '_name'])
      end
      csv_data.concat("#{criterion_array.join(',')},")
      criterion_array = []
      (0..4).each do |i|
        criterion_array.push(@criterion['level_' + i.to_s + '_description'])
      end
      csv_data.concat("#{criterion_array.join(',')}\n")
      expect(@controller).to receive(:send_data)
                               .with(csv_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.render nothing: true
      }
      get :download_csv,
          assignment_id: assignment.id
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get :download_csv,
          assignment_id: assignment.id
      expect(response.content_type).to eq 'text/csv'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get :download_csv,
          assignment_id: assignment.id
      filename = response.header['Content-Disposition']
        .split.last.split('"').second
      expect(filename).to eq "#{assignment.short_identifier}_rubric_criteria.csv"
    end
  end

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
        .to eq(rubric_criteria[0].name)
      expect(1).to eq(rubric_criteria[0].position)
      expect('Documentation').to eq(rubric_criteria[1].name)
      expect(2).to eq(rubric_criteria[1].position)
      expect('Testing').to eq(rubric_criteria[2].name)
      expect(3).to eq(rubric_criteria[2].position)
      expect('Correctness').to eq(rubric_criteria[3].name)
      expect(4).to eq(rubric_criteria[3].position)

      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq([I18n.t('csv_valid_lines',
                                            valid_line_count: 4)])
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
