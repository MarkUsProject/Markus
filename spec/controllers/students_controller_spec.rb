describe StudentsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  context '#upload' do
    include_examples 'a controller supporting upload' do
      let(:params) { {} }
    end
    it 'accepts a valid file' do
      post :upload, params: {
        upload_file: fixture_file_upload(
          'files/students/form_good.csv', 'text/csv')
      }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to action: 'index'

      student = Student.find_by(user_name: 'c5anthei')
      expect(student.first_name).to eq('George')
      expect(student.last_name).to eq('Antheil')
      student = Student.find_by(user_name: 'c5bennet')
      expect(student.first_name).to eq('Robert Russell')
      expect(student.last_name).to eq('Bennett')
    end

    it 'does not accept files with invalid columns' do
      post :upload, params: {
        upload_file: fixture_file_upload(
          'files/students/form_invalid_column.csv', 'text/csv')
      }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: 'index'

      expect(Student.where(last_name: 'Antheil')).to be_empty
      expect(Student.where(user_name: 'c5bennet')).to be_empty
    end
  end
end
