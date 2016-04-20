require 'spec_helper'

describe StudentsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  context 'CSV_Uploads' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/students/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/students/form_good.csv',
                    'text/csv')))

      @file_invalid_column = fixture_file_upload(
        'files/students/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/students/form_invalid_column.csv',
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
      post :upload_student_list,
           userlist: @file_good

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to action: 'index'

      student = Student.where(user_name: 'c5anthei')
      expect(student.take['first_name']).to eq('George')
      expect(student.take['last_name']).to eq('Antheil')
      student = Student.where(user_name: 'c5bennet')
      expect(student.take['first_name']).to eq('Robert Russell')
      expect(student.take['last_name']).to eq('Bennett')
    end

    it 'does not accept files with invalid columns' do
      post :upload_student_list,
           userlist: @file_invalid_column

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'

      expect(Student.where(user_name: 'c5bennet')).to be_empty
    end

    it 'does not accept fileless submission' do
      post :upload_student_list

      expect(response.status).to eq(302)
      expect(response).to redirect_to action: 'index'
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :upload_student_list,
           userlist: @file_bad_csv

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
    end

    it 'does not accept a .xls file' do
      post :upload_student_list,
           userlist: @file_wrong_format

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'
      expect(flash[:error])
        .to eq([I18n.t('csv.upload.non_text_file_with_csv_extension')])
    end
  end
end
