describe MarksGradersController do
  let(:instructor) { create(:instructor) }
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:course) { grade_entry_form.course }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }

  describe '#upload' do
    it_behaves_like 'a controller supporting upload' do
      let(:params) { { course_id: course.id, grade_entry_form_id: grade_entry_form.id, model: GradeEntryStudentTa } }
    end

    before do
      # initialize students and a TA (these users must exist in order
      # to align with grader_student_form_good.csv)
      grade_entry_form_with_data
      @student_user_names = %w[c8shosta c5bennet]
      @student_user_names.each do |name|
        create(:student, user: create(:end_user, user_name: name))
      end
      @ta = create(:ta, user: create(:end_user, user_name: 'c6conley'))

      @file_good = fixture_file_upload('marks_graders/form_good.csv', 'text/csv')
    end

    ['.csv', '', '.pdf'].each do |extension|
      ext_string = extension.empty? ? 'none' : extension
      it "accepts a valid file with extension '#{ext_string}' and can preserve existing TA mappings" do
        file = fixture_file_upload("marks_graders/form_good#{extension}", 'text/csv')
        create(:student, user: create(:end_user, user_name: 'c5granad'))
        ges = grade_entry_form_with_data.grade_entry_students
                                        .joins(:user)
                                        .find_by('users.user_name': 'c5granad')
        create(:grade_entry_student_ta, grade_entry_student: ges, ta: @ta)
        post_as instructor,
                :upload,
                params: {
                  course_id: course.id,
                  grade_entry_form_id: grade_entry_form_with_data.id,
                  upload_file: file
                }

        expect(response).to have_http_status(:found)
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to(action: 'index',
                                        grade_entry_form_id:
                                          grade_entry_form_with_data.id)

        # check that the ta was assigned to each student
        @student_user_names.each do |name|
          expect(
            GradeEntryStudentTa.joins(grade_entry_student: :user)
                               .exists?('users.user_name': name)
          ).to be true
        end
        expect(ges.tas.count).to eq 1
      end

      it "accepts a valid file with extension '#{ext_string}' and can remove existing TA mappings" do
        create(:student, user: create(:end_user, user_name: 'c5granad'))
        ges = grade_entry_form_with_data.grade_entry_students
                                        .joins(:user)
                                        .find_by('users.user_name': 'c5granad')
        create(:grade_entry_student_ta, grade_entry_student: ges, ta: @ta)
        post_as instructor,
                :upload,
                params: {
                  course_id: course.id,
                  grade_entry_form_id: grade_entry_form_with_data.id,
                  upload_file: @file_good,
                  remove_existing_mappings: true
                }

        expect(response).to have_http_status(:found)
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to(action: 'index',
                                        grade_entry_form_id:
                                          grade_entry_form_with_data.id)

        # check that the ta was assigned to each student
        @student_user_names.each do |name|
          expect(
            GradeEntryStudentTa.joins(grade_entry_student: :user)
                               .exists?(grade_entry_student: { users: { user_name: name } })
          ).to be true
        end
        expect(ges.tas.count).to eq 0
      end
    end
  end

  describe '#grader_mapping' do
    it 'responds with appropriate status' do
      get_as instructor, :grader_mapping,
             params: { course_id: course.id, grade_entry_form_id: grade_entry_form.id }, format: 'csv'
      expect(response).to have_http_status(:ok)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get_as instructor, :grader_mapping,
             params: { course_id: course.id, grade_entry_form_id: grade_entry_form.id }, format: 'csv'
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      student = create(:student)
      grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(role: student)
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
      get_as instructor, :grader_mapping,
             params: { course_id: course.id, grade_entry_form_id: grade_entry_form.id }, format: 'csv'
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get_as instructor, :grader_mapping,
             params: { course_id: course.id, grade_entry_form_id: grade_entry_form.id }, format: 'csv'
      expect(response.media_type).to eq 'text/csv'
    end
  end

  describe '#assign_all' do
    before do
      allow(GradeEntryStudent).to receive(:assign_all_tas)
    end

    context 'when students and graders are selected' do
      it 'calls GradeEntryStudent `assign_all` and return a success response' do
        student = create(:student)
        grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(role: student)
        grade_entry_student_ta = create(:grade_entry_student_ta, grade_entry_student: grade_entry_student)

        expect(GradeEntryStudent).to receive(:assign_all_tas).with(
          [grade_entry_student.id.to_s],
          [grade_entry_student_ta.id.to_s],
          grade_entry_form
        )

        post_as instructor, :assign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [grade_entry_student.id],
          graders: [grade_entry_student_ta.id]
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when students are not selected' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :assign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [],
          graders: [1]
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('groups.select_a_student'))
      end
    end

    context 'when graders are not selected' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :assign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [1],
          graders: []
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('graders.select_a_grader'))
      end
    end

    context 'when students parameter is missing' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :assign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          graders: [1]
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('groups.select_a_student'))
      end
    end

    context 'when graders parameter is missing' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :assign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [1]
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('graders.select_a_grader'))
      end
    end
  end

  describe '#unassign_all' do
    before do
      allow(GradeEntryStudent).to receive(:unassign_tas)
    end

    context 'when students and graders are selected' do
      it 'calls GradeEntryStudent `unassign_all` and return a success response' do
        student = create(:student)
        grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(role: student)
        grade_entry_student_ta = create(:grade_entry_student_ta, grade_entry_student: grade_entry_student)

        expect(GradeEntryStudent).to receive(:unassign_tas).with(
          [grade_entry_student.id.to_s],
          [grade_entry_student_ta.id.to_s],
          grade_entry_form
        )

        post_as instructor, :unassign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [grade_entry_student.id],
          graders: [grade_entry_student_ta.id]
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when students are not selected' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [],
          graders: [1]
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('groups.select_a_student'))
      end
    end

    context 'when graders are not selected' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [1],
          graders: []
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('graders.select_a_grader'))
      end
    end

    context 'when students parameter is missing' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          graders: [1]
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('groups.select_a_student'))
      end
    end

    context 'when graders parameter is missing' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_all, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          students: [1]
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('graders.select_a_grader'))
      end
    end
  end

  describe '#unassign_single' do
    before do
      allow(GradeEntryStudent).to receive(:unassign_tas)
    end

    context 'when students and graders are selected' do
      it 'calls GradeEntryStudent `unassign_single` and return a success response' do
        student = create(:student)
        grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(role: student)
        grade_entry_student_ta = create(:grade_entry_student_ta, grade_entry_student: grade_entry_student)

        expect(GradeEntryStudent).to receive(:unassign_tas).with(
          [grade_entry_student.id.to_s],
          [grade_entry_student_ta.ta.id],
          grade_entry_form
        )

        post_as instructor, :unassign_single, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          student_id: grade_entry_student.id,
          grader_user_name: grade_entry_student_ta.ta.user_name
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when student id is not selected' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_single, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          student_id: nil,
          grader_user_name: 'grader'
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('groups.select_a_student'))
      end
    end

    context 'when grader name is not selected' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_single, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          student_id: 1,
          grader_user_name: nil
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('graders.select_a_grader'))
      end
    end

    context 'when student id parameter is missing' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_single, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          grader_user_name: 'grader'
        }

        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('groups.select_a_student'))
      end
    end

    context 'when grader name parameter is missing' do
      it 'returns bad request and sets flash error' do
        post_as instructor, :unassign_single, params: {
          course_id: course.id,
          grade_entry_form_id: grade_entry_form.id,
          student_id: 1
        }
        expect(response).to have_http_status(:bad_request)
        expect(flash[:error]).to have_message(I18n.t('graders.select_a_grader'))
      end
    end
  end
end
