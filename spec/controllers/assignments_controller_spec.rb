require 'spec_helper'

describe AssignmentsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:annotation_category) { FactoryGirl.create(:annotation_category) }

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

  context 'CSV_Downloads' do
    let(:csv_options) do
      {
        type: 'text/csv',
        filename: 'assignment_list.csv',
        disposition: 'attachment'
      }
    end

    before :each do
      # for some reason, assignments aren't always cleared from the db
      # before these tests
      Assignment.all.each do |asn|
        asn.delete
      end
      @assignment = FactoryGirl.create(:assignment)
    end

    it 'responds with appropriate status' do
      get :download_assignment_list, file_format: 'csv'
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :download_assignment_list, file_format: 'csv'
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      # copied from the controller
      DEFAULT_FIELDS = [:short_identifier, :description, :repository_folder,
                        :due_date, :message, :group_min, :group_max,
                        :tokens_per_period, :allow_web_submits,
                        :student_form_groups, :remark_due_date,
                        :remark_message, :assign_graders_to_criteria,
                        :enable_test, :enable_student_tests, :allow_remarks,
                        :display_grader_names_to_students,
                        :group_name_autogenerated, :is_hidden, :vcs_submit,
                        :has_peer_review]
      # generate the expected csv string
      csv_data = []
      DEFAULT_FIELDS.map do |f|
        csv_data << @assignment.send(f.to_s)
      end
      expect(@controller).to receive(:send_data)
                               .with(csv_data.join(',') + "\n", csv_options) {
        # to prevent a 'missing template' error
        @controller.render nothing: true
      }
      get :download_assignment_list, file_format: 'csv'
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get :download_assignment_list, file_format: 'csv'
      expect(response.content_type).to eq 'text/csv'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get :download_assignment_list, file_format: 'csv'
      filename = response.header['Content-Disposition']
        .split.last.split('"').second
      expect(filename).to eq 'assignment_list.csv'
    end
  end
end
