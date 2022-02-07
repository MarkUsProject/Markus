describe CoursesController do
  let(:instructor) { create :instructor }
  let(:course) { instructor.course }
  describe '#switch_role' do
    # before do
    #   allow(controller).to receive(:render)
    # end
    let(:student_in_course) { create :student }
    let(:second_instructor) { create :instructor }
    it 'fails when switching role as the current instructor' do
      post_as instructor, :switch_role,
              params: { 'effective_user_login' => instructor.user_id, 'commit' => 'Log in', 'id' => course.id }
      expect(response.status).to eq(404)
    end
    it 'succeeds when switching role as a student in the course' do
      post_as instructor, :switch_role,
              params: { 'effective_user_login' => student_in_course.user_id, 'commit' => 'Log in', 'id' => course.id }
      expect(response.status).to eq(200)
    end
    it 'fails when switching role as another instructor in the course' do
      post_as instructor, :switch_role,
              params: { 'effective_user_login' => second_instructor.user_id, 'commit' => 'Log in', 'id' => course.id }
      expect(response.status).to eq(404)
    end
  end
  describe '#clear_role_switch_session' do
    let!(:subject) { get_as instructor, :clear_role_switch_session, params: { 'id' => course.id } }
    it 'redirects to show' do
      expect(controller).to redirect_to action: :show, id: course.id
    end
    it "sets this session's username to nil" do
      expect(session[:user_name]).to be(nil)
    end
    it "sets this session's role_switch_course_id to nil" do
      expect(session[:role_switch_course_id]).to be(nil)
    end
  end

  context 'accessing course pages' do
    it 'responds with success on index' do
      get_as instructor, :index
      expect(response.status).to eq(200)
    end
    it 'responds with success on show' do
      get_as instructor, :show, params: { id: course }
      expect(response.status).to eq(200)
    end
  end
  context '#upload_assignments' do
    include_examples 'a controller supporting upload', route_name: :upload_assignments do
      let(:params) { { id: course.id } }
    end

    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload('assignments/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload('assignments/form_good.csv', 'text/csv'))
      )
      @file_good_yml = fixture_file_upload('assignments/form_good.yml', 'text/yaml')
      allow(@file_good_yml).to receive(:read).and_return(
        File.read(fixture_file_upload('assignments/form_good.yml', 'text/yaml'))
      )

      @file_invalid_column = fixture_file_upload('assignments/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload('assignments/form_invalid_column.csv', 'text/csv'))
      )

      # This must line up with the second entry in the file_good
      @test_asn1 = 'ATest1'
      @test_asn2 = 'ATest2'
    end

    it 'accepts a valid file' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_good }

      expect(response.status).to eq(302)
      test1 = Assignment.find_by(short_identifier: @test_asn1)
      expect(test1).to_not be_nil
      test2 = Assignment.find_by(short_identifier: @test_asn2)
      expect(test2).to_not be_nil
      expect(flash[:error]).to be_nil
      expect(flash[:success].map { |f| extract_text f }).to eq([I18n.t('upload_success',
                                                                       count: 2)].map { |f| extract_text f })
      expect(response).to redirect_to(course_assignments_path(course))
    end

    it 'accepts a valid YAML file' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_good_yml }

      expect(response.status).to eq(302)
      test1 = Assignment.find_by_short_identifier(@test_asn1)
      expect(test1).to_not be_nil
      test2 = Assignment.find_by_short_identifier(@test_asn2)
      expect(test2).to_not be_nil
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(course_assignments_path(course))
    end

    it 'does not accept files with invalid columns' do
      post_as instructor, :upload_assignments, params: { id: course.id, upload_file: @file_invalid_column }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      test = Assignment.find_by_short_identifier(@test_asn2)
      expect(test).to be_nil
      expect(response).to redirect_to(course_assignments_path(course))
    end
  end
  context 'CSV_Downloads' do
    let(:csv_options) do
      { type: 'text/csv', filename: 'assignments.csv', disposition: 'attachment' }
    end
    let!(:assignment) { create(:assignment) }

    it 'responds with appropriate status' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      # generate the expected csv string
      csv_data = []
      Assignment::DEFAULT_FIELDS.map do |f|
        csv_data << assignment.public_send(f)
      end
      new_data = csv_data.join(',') + "\n"
      expect(@controller).to receive(:send_data).with(new_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      expect(response.media_type).to eq 'text/csv'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'csv' }
      filename = response.header['Content-Disposition'].split[1].split('"').second
      expect(filename).to eq 'assignments.csv'
    end
  end
  context 'YML_Downloads' do
    let(:yml_options) do
      { type: 'text/yml', filename: 'assignments.yml', disposition: 'attachment' }
    end
    let!(:assignment) { create(:assignment) }

    it 'responds with appropriate status' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      # generate the expected yml string
      assignments = Assignment.all
      map = {}
      map[:assignments] = assignments.map do |assignment|
        m = {}
        Assignment::DEFAULT_FIELDS.each do |f|
          m[f] = assignment.public_send(f)
        end
        m
      end
      map = map.to_yaml
      expect(@controller).to receive(:send_data).with(map, yml_options) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
    end

    # parse header object to check for the right content type
    it 'returns text/yml type' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      expect(response.media_type).to eq 'text/yml'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get_as instructor, :download_assignments, params: { id: course.id, format: 'yml' }
      filename = response.header['Content-Disposition'].split[1].split('"').second
      expect(filename).to eq 'assignments.yml'
    end
  end
end
