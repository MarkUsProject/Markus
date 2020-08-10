describe GradeEntryFormsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))

    # initialize student DB entries
    @student = create(:student, user_name: 'c8shosta')
  end

  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:grade_entry_form_with_data_and_total) { create(:grade_entry_form_with_data_and_total) }

  describe '#upload' do
    before :each do
      @file_invalid_username =
        fixture_file_upload('files/grade_entry_forms/invalid_username.csv',
                            'text/csv')
      @file_extra_column =
        fixture_file_upload('files/grade_entry_forms/extra_column.csv',
                            'text/csv')
      @file_different_total =
        fixture_file_upload('files/grade_entry_forms/different_total.csv',
                            'text/csv')
      @file_good =
        fixture_file_upload('files/grade_entry_forms/good.csv',
                            'text/csv')
      @file_good_overwrite =
        fixture_file_upload('files/grade_entry_forms/good_overwrite.csv',
                            'text/csv')

      @file_total_included = fixture_file_upload('files/grade_entry_forms/total_column_included.csv', 'text/csv')

      @student = grade_entry_form_with_data.grade_entry_students.joins(:user).find_by('users.user_name': 'c8shosta')
      @original_item = grade_entry_form_with_data.grade_entry_items.first
      @student.grades.find_or_create_by(grade_entry_item: @original_item).update(
        grade: 50
      )
    end

    include_examples 'a controller supporting upload' do
      let(:params) { { id: grade_entry_form.id, model: Grade } } # model: Grade checks the number of grades.
    end

    it 'can accept valid file without overriding existing columns, even if those columns do not appear in the file' do
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_good }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
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
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_good, overwrite: true }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
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
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_good_overwrite, overwrite: true }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
      )

      # Check that the existing column still exists, and the student's grade has been changed.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: @original_item.name)).to_not be_nil
      expect(@student.grades.reload.find_by(grade_entry_item: @original_item).grade).to eq 89
    end

    it 'can accept valid file without overriding existing grades' do
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_good_overwrite }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
      )

      # Check that the existing column still exists, and the student's grade has not been changed.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: @original_item.name)).to_not be_nil
      expect(@student.grades.reload.find_by(grade_entry_item: @original_item).grade).to eq 50
    end

    it 'reports rows with an invalid username, but still processes the rest of the file' do
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_invalid_username }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
      )

      # Check that the two columns were still created.
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test')).to_not be_nil
      expect(grade_entry_form_with_data.grade_entry_items.find_by(name: 'Test2')).to_not be_nil
    end

    it 'accepts files with additional columns, and can reorder existing columns' do
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_extra_column }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
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
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_different_total }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en')
      )

      # Check that the original column's total has been updated.
      expect(grade_entry_form_with_data.grade_entry_items.first.out_of).to eq 101
    end

    it 'ignores the total column if given in the csv file' do
      post :upload, params: { id: grade_entry_form_with_data.id, upload_file: @file_total_included, overwrite: true }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))

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
      @user = User.where(user_name: 'c8shosta').first
    end

    it 'returns a 200 status code' do
      get :download, params: { id: grade_entry_form }
      expect(response.status).to eq(200)
    end

    it 'expects a call to send_data' do
      grade_entry_item = grade_entry_form_with_data.grade_entry_items[0]
      student_grade = grade_entry_form_with_data.grade_entry_students
                                                .find_by(user: @user)
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
      get :download, params: { id: grade_entry_form_with_data }
    end

    it 'sets filename correctly' do
      get :download, params: { id: grade_entry_form }
      filename = "filename=\"#{grade_entry_form.short_identifier}_grades_report.csv\""
      expect(response.header['Content-Disposition'].split(';')[1].strip).to eq filename
    end

    # parse header object to check for the right content type
    it 'sets the content type to text/csv' do
      get :download, params: { id: grade_entry_form }
      expect(response.media_type).to eq 'text/csv'
    end

    it 'shows Total column when show_total is true' do
      csv_array = [
        ['',
         grade_entry_form_with_data_and_total.grade_entry_items[0].name,
         GradeEntryForm.human_attribute_name(:total)],
        [GradeEntryItem.human_attribute_name(:out_of),
         String(grade_entry_form_with_data_and_total.grade_entry_items[0].out_of),
         grade_entry_form_with_data_and_total.out_of_total],
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
      get :download, params: { id: grade_entry_form_with_data_and_total }
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
         gef.out_of_total],
        [ges.user.user_name, '', '50.0', '', '50.0']
      ]
      csv_data = MarkusCsv.generate(csv_array) do |data|
        data
      end

      expect(@controller).to receive(:send_data).with(
        csv_data,
        filename: "#{gef.short_identifier}_grades_report.csv",
        **csv_options
      ) { @controller.head :ok }
      get :download, params: { id: gef }
    end
  end

  describe '#update' do
    it 'clears date if blank' do
      expect(grade_entry_form.due_date).to_not be_nil
      patch :update, params: { id: grade_entry_form, grade_entry_form: { due_date: nil } }
      expect(grade_entry_form.reload.due_date).to be_nil
    end

    it 'updates date field' do
      expect(grade_entry_form.due_date).to_not be_nil
      patch :update, params: { id: grade_entry_form.id, grade_entry_form: { due_date: '2019-11-14' } }
      expect(grade_entry_form.reload.due_date.to_date).to eq Date.new(2019, 11, 14)
    end
  end

  describe '#update' do
    it 'clears date if blank' do
      expect(grade_entry_form.due_date).to_not be_nil
      patch :update, params: { id: grade_entry_form, grade_entry_form: { due_date: nil } }
      expect(grade_entry_form.reload.due_date).to be_nil
    end

    it 'updates date field' do
      expect(grade_entry_form.due_date).to_not be_nil
      patch :update, params: { id: grade_entry_form.id, grade_entry_form: { due_date: '2019-11-14' } }
      expect(grade_entry_form.reload.due_date.to_date).to eq Date.new(2019, 11, 14)
    end
  end

  describe 'update_grade_entry_students' do
    before :each do
      create(:student, user_name: 'paneroar')
      @student = grade_entry_form_with_data.grade_entry_students.joins(:user).find_by('users.user_name': 'c8shosta')
      @another = grade_entry_form_with_data.grade_entry_students.joins(:user).find_by('users.user_name': 'paneroar')
      @this_form = grade_entry_form_with_data
    end

    around { |example| perform_enqueued_jobs(&example) }

    it 'sends an email to a student who has grades for this form if only one exists' do
      expect do
        post :update_grade_entry_students,
             params: { id: @this_form.id,
                       students: [@student.id],
                       release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
    it 'sends an email to every student who has grades for this form if more than one do' do
      expect do
        post :update_grade_entry_students,
             params: { id: @this_form.id,
                       students: [@student.id, @another.id],
                       release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(2)
    end
    it 'does not send emails if all the students have results notifications turned off' do
      @student.user.update!(receives_results_emails: false)
      @another.user.update!(receives_results_emails: false)
      expect do
        post :update_grade_entry_students,
             params: { id: @this_form.id,
                       students: [@student.id, @another.id],
                       release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(0)
    end
    it 'sends emails to students that have have results notifications enabled if only some do' do
      @student.user.update!(receives_results_emails: false)
      expect do
        post :update_grade_entry_students,
             params: { id: @this_form.id,
                       students: [@student.id, @another.id],
                       release_results: 'true' }
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe '#student_interface' do
    before :each do
      allow(controller).to receive(:current_user).and_return(@student)
    end

    it 'does not allow students to see hidden grade entry forms' do
      grade_entry_form.update!(is_hidden: true)
      get_as @student, :student_interface, params: { id: grade_entry_form.id }
      assert_response 404
    end

    it 'allows students to see non hidden grade entry forms' do
      get_as @student, :student_interface, params: { id: grade_entry_form.id }
      assert_response 200
    end
  end
end
