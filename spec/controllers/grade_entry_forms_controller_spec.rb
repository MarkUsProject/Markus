describe GradeEntryFormsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))

    # initialize student DB entries
    create(:student, user_name: 'c8shosta')
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
      csv_array = [
        ['', grade_entry_form_with_data.grade_entry_items[0].name],
        [GradeEntryItem.human_attribute_name(:out_of), String(grade_entry_form_with_data.grade_entry_items[0].out_of)],
        [@user.user_name, '']
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
  end
end
