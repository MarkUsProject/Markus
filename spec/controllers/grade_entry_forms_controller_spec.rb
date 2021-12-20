describe GradeEntryFormsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  before :each do
    # initialize student DB entries
    @student = create(:student, end_user: create(:end_user, user_name: 'c8shosta'))
  end
  let(:role) { create :instructor }
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:course) { grade_entry_form.course }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:grade_entry_form_with_data_and_total) { create(:grade_entry_form_with_data_and_total) }

  describe '#upload' do
    before :each do
      @file_invalid_username =
        fixture_file_upload('grade_entry_forms/invalid_username.csv',
                            'text/csv')
      @file_extra_column =
        fixture_file_upload('grade_entry_forms/extra_column.csv',
                            'text/csv')
      @file_different_total =
        fixture_file_upload('grade_entry_forms/different_total.csv',
                            'text/csv')
      @file_good =
        fixture_file_upload('grade_entry_forms/good.csv',
                            'text/csv')
      @file_good_overwrite =
        fixture_file_upload('grade_entry_forms/good_overwrite.csv',
                            'text/csv')

      @file_total_included = fixture_file_upload('grade_entry_forms/total_column_included.csv', 'text/csv')

      @student = grade_entry_form_with_data.grade_entry_students
                                           .joins(role: :end_user)
                                           .find_by('users.user_name': 'c8shosta')
      @original_item = grade_entry_form_with_data.grade_entry_items.first
      @student.grades.find_or_create_by(grade_entry_item: @original_item).update(
        grade: 50
      )
    end

    include_examples 'a controller supporting upload' do
      let(:params) { { course_id: course.id, id: grade_entry_form.id, model: Grade } }
    end

    it 'can accept valid file without overriding existing columns, even if those columns do not appear in the file' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id, upload_file: @file_good }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_course_grade_entry_form_path(course, grade_entry_form_with_data)
      )

      # Check that the new column and grade are created
      new_item = grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test')
      expect(new_item.out_of).to eq 100
      expect(@student.grades.find_by(grade_entry_item: new_item).grade).to eq 89

      # Check that the existing column and grade still exist.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: @original_item.name)).to_not be_nil
      expect(@student.grades.find_by(grade_entry_item: @original_item).grade).to eq 50
    end

    it 'can accept valid file and override existing columns' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id,
                        upload_file: @file_good, overwrite: true }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_course_grade_entry_form_path(course, grade_entry_form_with_data)
      )

      # Check that the new column and grade are created
      new_item = grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test')
      expect(new_item.out_of).to eq 100
      expect(@student.grades.find_by(grade_entry_item: new_item).grade).to eq 89

      # Check that the existing column and grade no longer exist.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: @original_item.name)).to be_nil
      expect(@student.grades.find_by(grade_entry_item: @original_item)).to be_nil
    end

    it 'can accept valid file and override existing grades' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id,
                        upload_file: @file_good_overwrite, overwrite: true }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_course_grade_entry_form_path(course, grade_entry_form_with_data)
      )

      # Check that the existing column still exists, and the student's grade has been changed.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: @original_item.name)).to_not be_nil
      expect(@student.grades.reload.find_by(grade_entry_item: @original_item).grade).to eq 89
    end

    it 'can accept valid file without overriding existing grades' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id, upload_file: @file_good_overwrite }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_course_grade_entry_form_path(course, grade_entry_form_with_data)
      )

      # Check that the existing column still exists, and the student's grade has not been changed.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: @original_item.name)).to_not be_nil
      expect(@student.grades.reload.find_by(grade_entry_item: @original_item).grade).to eq 50
    end

    it 'reports rows with an invalid username, but still processes the rest of the file' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id, upload_file: @file_invalid_username }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_course_grade_entry_form_path(course, grade_entry_form_with_data)
      )

      # Check that the two columns were still created.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test')).to_not be_nil
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test2')).to_not be_nil
    end

    it 'accepts files with additional columns, and can reorder existing columns' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id, upload_file: @file_extra_column }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_course_grade_entry_form_path(course, grade_entry_form_with_data)
      )

      # Check that the new column and grade are created
      new_item = grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test2')
      expect(new_item.out_of).to eq 100
      expect(new_item.position).to eq 1
      expect(@student.grades.find_by(grade_entry_item: new_item).grade).to eq 64
      original_item = grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test1')
      expect(original_item.position).to eq 2
    end

    it 'accepts files with a different grade total' do
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id, upload_file: @file_different_total }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(grades_course_grade_entry_form_path(course, grade_entry_form_with_data))

      # Check that the original column's total has been updated.
      expect(grade_entry_form_with_data.grade_entry_items.first.out_of).to eq 101
    end

    it 'ignores the total column when uploading a csv file with a <Total> column, when show_total is set to true' do
      grade_entry_form_with_data.update(show_total: true)
      post_as role, :upload,
              params: { course_id: course.id, id: grade_entry_form_with_data.id,
                        upload_file: @file_total_included, overwrite: true }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(grades_course_grade_entry_form_path(course, grade_entry_form_with_data))

      # Check that the total column is the actual total and not the incorrect total given in the file
      expect(@student.grades.first.grade).to eq 22
      expect(@student.reload.total_grade).to eq 22
    end
  end

  describe '#download' do
    let(:csv_options) do
      {
        disposition: 'attachment',
        type: 'text/csv'
      }
    end

    before :each do
      @user = @student.end_user
    end

    it 'returns a 200 status code' do
      get_as role, :download, params: { course_id: course.id, id: grade_entry_form }
      expect(response.status).to eq(200)
    end

    it 'expects a call to send_data' do
      grade_entry_item = grade_entry_form_with_data.grade_entry_items[0]
      student_grade = grade_entry_form_with_data.grade_entry_students
                                                .find_by(role: @student)
                                                .grades
                                                .find_by(grade_entry_item: grade_entry_item)
                                                .grade
      csv_array = [
        ['', grade_entry_item.name],
        [GradeEntryItem.human_attribute_name(:out_of), grade_entry_item.out_of],
        [@user.user_name, student_grade]
      ]
      csv_data = MarkusCsv.generate(csv_array) do |data|
        data
      end
      expect(@controller).to receive(:send_data).with(
        csv_data,
        filename: "#{grade_entry_form_with_data.short_identifier}_grades_report.csv",
        **csv_options
      ) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get_as role, :download, params: { course_id: course.id, id: grade_entry_form_with_data }
    end

    it 'sets filename correctly' do
      get_as role, :download, params: { course_id: course.id, id: grade_entry_form }
      filename = "filename=\"#{grade_entry_form.short_identifier}_grades_report.csv\""
      expect(response.header['Content-Disposition'].split(';')[1].strip).to eq filename
    end

    # parse header object to check for the right content type
    it 'sets the content type to text/csv' do
      get_as role, :download, params: { course_id: course.id, id: grade_entry_form }
      expect(response.media_type).to eq 'text/csv'
    end

    it 'shows Total column when show_total is true' do
      csv_array = [
        ['',
         grade_entry_form_with_data_and_total.grade_entry_items[0].name,
         GradeEntryForm.human_attribute_name(:total)],
        [GradeEntryItem.human_attribute_name(:out_of),
         String(grade_entry_form_with_data_and_total.grade_entry_items[0].out_of),
         grade_entry_form_with_data_and_total.max_mark],
        [@user.user_name, '', '']
      ]
      csv_data = MarkusCsv.generate(csv_array) do |data|
        data
      end
      expect(@controller).to receive(:send_data).with(
        csv_data,
        filename: "#{grade_entry_form_with_data_and_total.short_identifier}_grades_report.csv",
        **csv_options
      ) { @controller.head :ok }
      get_as role, :download, params: { course_id: course.id, id: grade_entry_form_with_data_and_total }
    end

    it 'shows blank entries when no grade exists' do
      gef = create(:grade_entry_form, show_total: true)
      3.times do |i|
        create(:grade_entry_item, position: i + 1, grade_entry_form: gef)
      end
      ges = gef.grade_entry_students.first
      ges.grades.create(grade_entry_item: gef.grade_entry_items.find_by(position: 2), grade: 50)
      ges.save

      csv_array = [
        ['',
         gef.grade_entry_items[0].name,
         gef.grade_entry_items[1].name,
         gef.grade_entry_items[2].name,
         GradeEntryForm.human_attribute_name(:total)],
        [GradeEntryItem.human_attribute_name(:out_of),
         gef.grade_entry_items[0].out_of.to_s,
         gef.grade_entry_items[1].out_of.to_s,
         gef.grade_entry_items[2].out_of.to_s,
         gef.max_mark],
        [ges.role.user_name, '', '50.0', '', '50.0']
      ]
      csv_data = MarkusCsv.generate(csv_array) do |data|
        data
      end

      expect(@controller).to receive(:send_data).with(
        csv_data,
        filename: "#{gef.short_identifier}_grades_report.csv",
        **csv_options
      ) { @controller.head :ok }
      get_as role, :download, params: { course_id: course.id, id: gef }
    end
  end

  shared_examples '#update_grade_entry_students' do
    before :each do
      create(:student, end_user: create(:end_user, user_name: 'paneroar'))
      @student = grade_entry_form_with_data.grade_entry_students
                                           .joins(role: :end_user).find_by('users.user_name': 'c8shosta')
      @another = grade_entry_form_with_data.grade_entry_students
                                           .joins(role: :end_user).find_by('users.user_name': 'paneroar')
      @this_form = grade_entry_form_with_data
    end

    around { |example| perform_enqueued_jobs(&example) }

    it 'sends an email to a student who has grades for this form if only one exists' do
      expect do
        post_as user, :update_grade_entry_students,
                params: { id: @this_form.id,
                          course_id: course.id,
                          students: [@student.id],
                          release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
    it 'sends an email to every student who has grades for this form if more than one do' do
      expect do
        post_as user, :update_grade_entry_students,
                params: { id: @this_form.id,
                          course_id: course.id,
                          students: [@student.id, @another.id],
                          release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(2)
    end
    it 'does not send emails if all the students have results notifications turned off' do
      @student.role.update!(receives_results_emails: false)
      @another.role.update!(receives_results_emails: false)
      expect do
        post_as user, :update_grade_entry_students,
                params: { id: @this_form.id,
                          course_id: course.id,
                          students: [@student.id, @another.id],
                          release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(0)
    end
    it 'sends emails to students that have have results notifications enabled if only some do' do
      @student.role.update!(receives_results_emails: false)
      expect do
        post_as user, :update_grade_entry_students,
                params: { id: @this_form.id,
                          course_id: course.id,
                          students: [@student.id, @another.id],
                          release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe '#student_interface' do
    it 'does not allow students to see hidden grade entry forms' do
      grade_entry_form.update!(is_hidden: true)
      get_as @student, :student_interface, params: { course_id: course.id, id: grade_entry_form.id }
      assert_response 404
    end

    it 'allows students to see non hidden grade entry forms' do
      get_as @student, :student_interface, params: { course_id: course.id, id: grade_entry_form.id }
      assert_response 200
    end
  end

  shared_examples '#manage grade entry forms' do
    context '#new' do
      before { get_as user, :new, params: { course_id: course.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
    context '#create' do
      before do
        post_as user, :create,
                params: {
                  course_id: course.id,
                  grade_entry_form: {
                    short_identifier: 'G1',
                    description: 'Test form',
                    due_date: Time.current
                  }
                }
      end
      it('should respond with 302') { expect(response.status).to eq 302 }
    end
    context '#edit' do
      before { post_as user, :edit, params: { course_id: course.id, id: grade_entry_form.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
    context '#update' do
      it 'clears date if blank' do
        expect(grade_entry_form.due_date).to_not be_nil
        patch_as user, :update,
                 params: { course_id: course.id, id: grade_entry_form.id, grade_entry_form: { due_date: nil } }
        expect(grade_entry_form.reload.due_date).to be_nil
      end

      it 'updates date field' do
        expect(grade_entry_form.due_date).to_not be_nil
        patch_as user, :update,
                 params: { course_id: course.id, id: grade_entry_form.id, grade_entry_form: { due_date: '2019-11-14' } }
        expect(grade_entry_form.reload.due_date.to_date).to eq Date.new(2019, 11, 14)
      end
    end
  end
  describe 'When the user is instructor' do
    let(:user) { create(:instructor) }
    include_examples '#update_grade_entry_students'
    include_examples '#manage grade entry forms'
    context 'GET student interface' do
      before { get_as user, :student_interface, params: { course_id: course.id, id: grade_entry_form.id } }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end

  describe 'When the user is grader' do
    # By default all the grader permissions are set to false
    let(:user) { create(:ta) }
    describe 'When the grader is allowed to release and unrelease the grades' do
      let(:user) { create(:ta, manage_assessments: true) }
      include_examples '#update_grade_entry_students'
    end
    describe 'When the grader is not allowed to release and unrelease the grades' do
      let(:student) do
        grade_entry_form_with_data.grade_entry_students.joins(role: :end_user).find_by('users.user_name': 'c8shosta')
      end
      it 'should respond with 403' do
        post_as user, :update_grade_entry_students,
                params: { course_id: course.id,
                          id: grade_entry_form_with_data.id,
                          students: [student.id],
                          release_results: 'true' }
        expect(response.status).to eq 403
      end
    end
    describe 'When the grader is allowed to create, edit and update grade entry forms' do
      let(:user) { create(:ta, manage_assessments: true) }
      include_examples '#manage grade entry forms'
    end
    describe 'When the grader is not allowed to create, edit and update grade entry forms' do
      context '#new' do
        before { get_as user, :new, params: { course_id: course.id } }
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      context '#create' do
        before do
          post_as user, :create,
                  params: {
                    course_id: course.id,
                    grade_entry_form: {
                      short_identifier: 'G1',
                      description: 'Test form',
                      due_date: Time.current
                    }
                  }
        end
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      context '#edit' do
        before { post_as user, :edit, params: { course_id: course.id, id: grade_entry_form.id } }
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      context '#update' do
        it 'should respond with 403' do
          patch_as user, :update,
                   params: { course_id: course.id, id: grade_entry_form, grade_entry_form: { due_date: nil } }
          expect(response.status).to eq 403
        end
      end
    end
    context 'GET student interface' do
      before { get_as user, :student_interface, params: { course_id: course.id, id: grade_entry_form.id } }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end

  describe '#grade_distribution' do
    let(:user) { create(:instructor) }
    before { get_as user, :grade_distribution, params: { course_id: course.id, id: grade_entry_form_with_data.id } }

    it('should return grade distribution data') {
      expected_items = grade_entry_form_with_data.grade_distribution_array
      expect(response.parsed_body['grade_dist_data']['datasets'][0]['data']).to eq expected_items
    }

    it 'should retrieve the correct column data' do
      response_data = response.parsed_body['column_breakdown_data']

      gef_dataset = grade_entry_form_with_data.grade_entry_items.map do |item|
        { label: item.name, data: item.grade_distribution_array(20) }
      end
      expect(response_data['datasets']).to eq gef_dataset.as_json
    end

    it('should return the correct grade distribution labels') {
      new_labels = (0..19).map { |i| "#{5 * i}-#{5 * i + 5}" }
      expect(response.parsed_body['grade_dist_data']['labels']).to eq new_labels
    }

    it('should return the correct column data labels') {
      new_labels = (0..19).map { |i| "#{5 * i}-#{5 * i + 5}" }
      expect(response.parsed_body['column_breakdown_data']['labels']).to eq new_labels
    }

    it('should respond with 200') { expect(response).to have_http_status 200 }

    it 'should return the expected info summary' do
      name = grade_entry_form_with_data.short_identifier + ': ' + grade_entry_form_with_data.description
      total_students = grade_entry_form_with_data.grade_entry_students.joins(:role).where('roles.hidden': false).count
      expected_summary = { name: name,
                           date: I18n.l(grade_entry_form_with_data.due_date),
                           average: grade_entry_form_with_data.results_average,
                           median: grade_entry_form_with_data.results_median,
                           num_entries: grade_entry_form_with_data.count_non_nil.to_s +
                             '/' + total_students.to_s,
                           num_fails: grade_entry_form_with_data.results_fails,
                           num_zeros: grade_entry_form.results_zeros }
      expect(response.parsed_body['info_summary']).to eq expected_summary.as_json
    end
  end

  describe '#switch' do
    let(:gef) { create :grade_entry_form }
    let(:gef2) { create :grade_entry_form }

    shared_examples 'switch assignment tests' do
      before { controller.request.headers.merge('HTTP_REFERER': referer) }
      subject { expect get_as user, 'switch', params: { course_id: course.id, id: gef2.id } }
      context 'referred from a grade entry form url' do
        let(:referer) { course_grade_entry_form_url(course_id: course.id, id: gef.id) }
        it 'should redirect to the equivalent assignment page' do
          expect(subject).to redirect_to(course_grade_entry_form_url(course, gef2))
        end
      end
      context 'referred from a non grade entry form url' do
        let(:referer) { non_grade_entry_form_url&.call(course_id: course.id, grade_entry_form_id: gef.id) }
        it 'should redirect to the equivalent non assignment page' do
          skip if non_grade_entry_form_url.nil?
          expect(subject).to redirect_to(non_grade_entry_form_url.call(course_id: course.id,
                                                                       grade_entry_form_id: gef2.id))
        end
      end
      context 'referer is nil' do
        let(:referer) { nil }
        it 'should redirect to the fallback url' do
          expect(subject).to redirect_to(fallback_url.call(course_id: course.id, id: gef2.id))
        end
      end
      context 'referer is a url that does not include the grade entry form at all' do
        let(:referer) { course_notes_url(course) }
        it 'should redirect to the fallback url' do
          expect(subject).to redirect_to(fallback_url.call(course_id: course.id, id: gef2.id))
        end
      end
      context 'the referer url is some other site entirely' do
        let(:referer) { 'https://test.com' }
        it 'should redirect to the fallback url' do
          expect(subject).to redirect_to(fallback_url.call(course_id: course.id, id: gef2.id))
        end
      end
      context 'the referer url is not valid' do
        let(:referer) { '1234567' }
        it 'should redirect to the fallback url' do
          expect(subject).to redirect_to(fallback_url.call(course_id: course.id, id: gef2.id))
        end
      end
    end

    context 'an instructor' do
      let(:user) { create :instructor }
      let(:non_grade_entry_form_url) { ->(params) { course_grade_entry_form_marks_graders_url(params) } }
      let(:fallback_url) { ->(params) { edit_course_grade_entry_form_path(params) } }
      include_examples 'switch assignment tests'
    end
    context 'a grader' do
      let(:user) { create :ta, manage_assessments: true }
      let(:non_grade_entry_form_url) { ->(params) { course_grade_entry_form_marks_graders_url(params) } }
      let(:fallback_url) { ->(params) { grades_course_grade_entry_form_path(params) } }
      include_examples 'switch assignment tests'
    end
    context 'a student' do
      let(:user) { create :student }
      let(:non_grade_entry_form_url) { nil }
      let(:fallback_url) { ->(params) { student_interface_course_grade_entry_form_url(params) } }
      include_examples 'switch assignment tests'
    end
  end
end
