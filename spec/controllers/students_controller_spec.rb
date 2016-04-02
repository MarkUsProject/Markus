require 'spec_helper'

describe StudentsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  context 'download_student_list' do
    context 'csv' do
      let(:csv_options) do
        {
          type: 'text/csv',
          filename: 'student_list',
          disposition: 'attachment'
        }
      end

      before :each do
        # create some test students
        (0..4).each do
          create(:student)
        end
        @students = Student.order(:user_name)
      end

      it 'responds with appropriate status' do
        get :download_student_list,
            format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download_student_list,
            format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = ''
        @students.pluck(:user_name, :last_name, :first_name).each do |student|
          csv_data.concat("#{student.join(',')}\n")
        end
        expect(@controller).to receive(:send_data)
                                 .with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.render nothing: true
        }
        get :download_student_list,
            format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download_student_list,
            format: 'csv'
        expect(response.content_type).to eq 'text/csv'
      end

      # parse header object to check for the right file naming convention
      it 'filename passes naming conventions' do
        get :download_student_list,
            format: 'csv'
        filename = response.header['Content-Disposition']
          .split.last.split('"').second
        expect(filename).to eq 'student_list'
      end
    end
  end
end