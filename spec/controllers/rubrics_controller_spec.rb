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
      csv_data = "#{@criterion.rubric_criterion_name},#{@criterion.weight},"
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
end