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
      user = create(:user, user_name: name, type: 'Student')
      create(:grade_entry_student,
             user: user,
             grade_entry_form: grade_entry_form_with_data)
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
end
