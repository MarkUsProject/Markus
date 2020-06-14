describe MarksGradersController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }

  context '#upload' do
    include_examples 'a controller supporting upload' do
      let(:params) { { grade_entry_form_id: grade_entry_form.id, model: GradeEntryStudentTa } }
    end

    before :each do
      # initialize students and a TA (these users must exist in order
      # to align with grader_student_form_good.csv)
      grade_entry_form_with_data
      @student_user_names = %w[c8shosta c5bennet]
      @student_user_names.each do |name|
        create(:student, user_name: name)
      end
      @ta = create(:ta, user_name: 'c6conley')

      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/marks_graders/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
          'files/marks_graders/form_good.csv', 'text/csv')))
    end

    it 'accepts a valid file and can preserve existing TA mappings' do
      create(:student, user_name: 'c5granad')
      ges = grade_entry_form_with_data.grade_entry_students.joins(:user).find_by('users.user_name': 'c5granad')
      create(:grade_entry_student_ta, grade_entry_student: ges, ta: @ta)
      post :upload,
           params: {
             grade_entry_form_id: grade_entry_form_with_data.id,
             upload_file: @file_good
           }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                          grade_entry_form_with_data.id)

      # check that the ta was assigned to each student
      @student_user_names.each do |name|
        expect(
          GradeEntryStudentTa.joins(grade_entry_student: :user)
                             .where(grade_entry_student: { users: { user_name: name } } )
                             .exists?
        ).to be true
      end
      expect(ges.tas.count).to eq 1
    end

    it 'accepts a valid file and can remove existing TA mappings' do
      create(:student, user_name: 'c5granad')
      ges = grade_entry_form_with_data.grade_entry_students.joins(:user).find_by('users.user_name': 'c5granad')
      create(:grade_entry_student_ta, grade_entry_student: ges, ta: @ta)
      post :upload,
           params: {
             grade_entry_form_id: grade_entry_form_with_data.id,
             upload_file: @file_good,
             remove_existing_mappings: true
           }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(action: 'index',
                                      grade_entry_form_id:
                                        grade_entry_form_with_data.id)

      # check that the ta was assigned to each student
      @student_user_names.each do |name|
        expect(
          GradeEntryStudentTa.joins(grade_entry_student: :user)
            .where(grade_entry_student: { users: { user_name: name } })
            .exists?
        ).to be true
      end
      expect(ges.tas.count).to eq 0
    end
  end

  describe '#grader_mapping' do
    it 'responds with appropriate status' do
      get :grader_mapping, params: { grade_entry_form_id: grade_entry_form.id }, format: 'csv'
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :grader_mapping, params: { grade_entry_form_id: grade_entry_form.id }, format: 'csv'
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      student = create(:student)
      grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(user: student)
      grade_entry_student_ta = create(:grade_entry_student_ta, grade_entry_student: grade_entry_student)
      csv_data = "#{student.user_name},#{grade_entry_student_ta.ta.user_name}\n"
      expect(@controller).to receive(:send_data).with(
        csv_data,
        type: 'text/csv',
        disposition: 'attachment',
        filename: "#{grade_entry_form.short_identifier}_grader_mapping.csv"
      ) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get :grader_mapping, params: { grade_entry_form_id: grade_entry_form.id }, format: 'csv'
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get :grader_mapping, params: { grade_entry_form_id: grade_entry_form.id }, format: 'csv'
      expect(response.media_type).to eq 'text/csv'
    end
  end
end
