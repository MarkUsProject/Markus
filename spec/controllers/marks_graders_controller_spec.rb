require 'spec_helper'

describe MarksGradersController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))

    # initialize students and a TA (these users must exist in order
    # to align with grader_student_form_good.csv)
    @student_user_names = %w(c8shosta c5bennet)
    @student_user_names.each do |name|
      create(:user, user_name: name, type: 'Student')
    end
    @ta_user_name = 'c6conley'
    user = create(:user, user_name: @ta_user_name, type: 'Ta')
    create(:grade_entry_student,
           user: user,
           grade_entry_form: grade_entry_form_with_data)
  end

  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }

  context 'CSV_Uploads' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/marks_graders/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
          'files/marks_graders/form_good.csv', 'text/csv')))

      @file_invalid_column = fixture_file_upload(
        'files/marks_graders/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
          'files/marks_graders/form_invalid_column.csv', 'text/csv')))

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
      post :csv_upload_grader_groups_mapping,
           grade_entry_form_id: grade_entry_form_with_data.id,
           grader_mapping: @file_good

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                          grade_entry_form_with_data.id)

      # check that the ta was assigned to each student
      @student_user_names.each do |name|
        expect(@ta_user_name).to eq(GradeEntryStudent.joins(:user)
                                        .find_by(users: { user_name: name })
                                        .tas.first.user_name)
      end
    end

    it 'does not accept files with invalid columns' do
      post :csv_upload_grader_groups_mapping,
           grade_entry_form_id: grade_entry_form_with_data.id,
           grader_mapping: @file_invalid_column

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                          grade_entry_form_with_data.id)
    end

    it 'does not accept fileless submission' do
      post :csv_upload_grader_groups_mapping,
           grade_entry_form_id: grade_entry_form_with_data.id

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                          grade_entry_form_with_data.id)
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :csv_upload_grader_groups_mapping,
           grade_entry_form_id: grade_entry_form_with_data.id,
           grader_mapping: @file_bad_csv

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                          grade_entry_form_with_data.id)
    end

    it 'does not accept a .xls file' do
      post :csv_upload_grader_groups_mapping,
           grade_entry_form_id: grade_entry_form_with_data.id,
           grader_mapping: @file_wrong_format

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(flash[:error])
        .to eq([t('csv.upload.non_text_file_with_csv_extension')])
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                          grade_entry_form_with_data.id)
    end
  end

  context 'download_grader_students_mapping' do
    let(:csv_options) do
      {
        type: 'text/csv',
        disposition: 'attachment'
      }
    end

    before :each do
      # clear user's from any previous test suites
      User.all.each do |user|
        user.delete
      end
      @grade_entry_form = create(:grade_entry_form)
      @student = create(:student, user_name: 'c8shosta')
      @ta = create(:ta, user_name: 'c5bennet')
      @grade_entry_student = @grade_entry_form.grade_entry_students.find_by(user: @student)
      @grade_entry_student.add_tas_by_user_name_array([@ta.user_name])
    end

    it 'responds with appropriate status' do
      get :download_grader_students_mapping,
          grade_entry_form_id: @grade_entry_form.id,
          format: 'csv'
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :download_grader_students_mapping,
          grade_entry_form_id: @grade_entry_form.id,
          format: 'csv'
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment'
    end

    it 'expects a call to send_data' do
      csv_data =  "#{@student.user_name},#{@ta.user_name}\n"
      expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.render nothing: true
      }
      get :download_grader_students_mapping,
          grade_entry_form_id: @grade_entry_form.id,
          format: 'csv'
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get :download_grader_students_mapping,
          grade_entry_form_id: @grade_entry_form.id,
          format: 'csv'
      expect(response.content_type).to eq 'text/csv'
    end
  end
end
