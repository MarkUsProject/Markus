require 'spec_helper'

describe GradeEntryFormsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:new_grade) { 10.0 }
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:grade_entry_item) do
    GradeEntryItem.find_by_grade_entry_form_id(grade_entry_form_with_data)
  end
  let(:grade_entry_student) do
    GradeEntryStudent.find_by_grade_entry_form_id(grade_entry_form_with_data)
  end
  let(:grade) do
    Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
      grade_entry_student, grade_entry_item)
  end
  
  let(:old_grade) do
    Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
      grade_entry_student, grade_entry_item)
  end

  context 'CSV_Uploads' do
    before :each do
      @file_without_extension =
        fixture_file_upload('spec/fixtures/files/grade_entry_upload_empty_file',
                            'text/xml')
      @file_wrong_format =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_upload_wrong_format.xls', 'text/xls')
      @file_bad_csv =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_upload_bad_csv.csv', 'text/xls')
      @file_bad_endofline =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_upload_file_bad_endofline.csv',
          'text/csv')
      @file_invalid_username =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_form_invalid_username.csv',
          'text/csv')
      @file_extra_column =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_form_extra_column.csv',
          'text/csv')
      @file_different_column_name =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_form_different_column_name.csv',
          'text/csv')
      @file_different_total =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_form_different_total.csv',
          'text/csv')
      @file_good =
        fixture_file_upload(
          'spec/fixtures/files/grade_entry_form_good.csv',
          'text/csv')
      @file_good_ISO =
        fixture_file_upload(
          'spec/fixtures/files/test_grades_ISO-8859-1.csv',
          'text/csv')
      @file_good_UTF =
        fixture_file_upload(
          'spec/fixtures/files/test_grades_UTF-8.csv',
          'text/csv')
      
    end

    it 'accepts valid file' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_good }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      with = (grade_entry_form_with_data.id + 1).to_s
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
    end

    it 'accepts files with additional columns' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_extra_column }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      with = (grade_entry_form_with_data.id + 1).to_s
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
    end

    it 'does not accept csv file with an invalid username' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_invalid_username }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      with = (grade_entry_form_with_data.id + 1).to_s
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
    end

    it 'accepts files with a different column name' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_different_column_name }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      with = (grade_entry_form_with_data.id + 1).to_s
      expect(response).to redirect_to(
                                      grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
                                      #csv_overwrite_grade_entry_form_path(grade_entry_form_with_data,
                                      #with: with, locale: 'en'))
    end

    it 'accepts files with a different grade total' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_different_total }
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      with = (grade_entry_form_with_data.id + 1).to_s
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
    end

    it 'does not accept a csv file corrupt line endings' do
      post :csv_upload, id: grade_entry_form,
           upload: { grades_file: @file_bad_endofline }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end

    it 'does not accept a file with no extension' do
      post :csv_upload,
           id: grade_entry_form,
           upload: { grades_file: @file_without_extension }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end

    it 'does not accept fileless submission' do
      post :csv_upload, id: grade_entry_form
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end

    it 'should gracefully fail on non-csv file with .csv extension' do
      post :csv_upload, id: grade_entry_form,
           upload: { grades_file: @file_bad_csv }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end

    it 'should gracefully fail on .xls file' do
      post :csv_upload,
           id: grade_entry_form,
           upload: { grades_file: @file_wrong_format }
      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form, locale: 'en'))
    end
    
    it 'should have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_good_ISO },
           encoding: 'ISO-8859-1'
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
      expect(grade_entry_item.name).to eq 'something'
      expect(grade_entry_item.out_of).to eq 10.0
      expect(grade.grade).to_not be_nil
      expect(grade.grade).to eq new_grade
    end

    it 'should have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_good_UTF },
           encoding: 'UTF-8'
      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
      expect(grade.grade).to_not be_nil
      expect(grade.grade).to eq new_grade
    end

    it 'should update old grades' do
      #??????????expect(old_grade).to be_nil
      post :csv_upload,
           id: grade_entry_form_with_data,
           upload: { grades_file: @file_good_UTF },
           encoding: 'UTF-8'
      expect(response).to redirect_to(
        grades_grade_entry_form_path(grade_entry_form_with_data, locale: 'en'))
      grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
                grade_entry_student, grade_entry_item)
      expect(grade.grade).to_not be_nil
      expect(grade.grade).to eq new_grade
    # grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
    #                                                                      @grade_entry_student.id, @grade_entry_item.id
    #                                                                      )
    #                                                                      assert_not_nil grade
    #                                                                      assert_equal @old_grade, grade.grade
    #                                                                      post_as @admin,
    #                                                                      :csv_upload,
    #                                                                      :id => @grade_entry_form.id,
    #                                                                      :upload => {:grades_file => fixture_file_upload('files/test_grades_UTF-8.csv')},
    #                                                                      :encoding => 'UTF-8'
    #                                                                      assert_response :redirect
    #                                                                      grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
    #                                                                            @grade_entry_student.id, @grade_entry_item.id
    #                                                                                                                           )
    #                                                                                                                     assert_not_nil grade
    #                                                                                         assert_equal @new_grade, grade.grade
    end

#should 'delete unused columns' do
# post_as @admin,
# :csv_upload,
# :id => @grade_entry_form.id,
# :upload => {:grades_file => fixture_file_upload('files/test_grades_UTF-8.csv')},
# :encoding => 'UTF-8'
# assert_response :redirect
#
# grade_entry_item = GradeEntryItem.find_by_id(@grade_entry_item.id)
# assert_nil grade_entry_item
#end

#should 'delete unused grades' do
# post_as @admin,
# :csv_upload,
# :id => @grade_entry_form.id,
# :upload => {:grades_file => fixture_file_upload('files/test_grades_UTF-8.csv')},
# :encoding => 'UTF-8'
# assert_response :redirect
# old_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
#                                                                          @grade_entry_student.id, @grade_entry_item.id
#                                                                          )
#                                                                          assert_nil old_grade
#                                                                          new_grade_entry_item = GradeEntryItem.find_by_name('something')
##                                                                          assert_not_nil new_grade_entry_item
#                                                                         new_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
#                                                                                                         @grade_entry_student.id, new_grade_entry_item.id
#                                                                                                                                                    )
#                                                                                                                         assert_not_nil new_grade
#end

  end

  context 'CSV_Downloads' do
    let(:csv_data) { grade_entry_form.get_csv_grades_report }
    let(:csv_options) do
      {
        filename: "#{grade_entry_form.short_identifier}_grades_report.csv",
        disposition: 'attachment',
        type: 'application/vnd.ms-excel'
      }
    end

    it 'tests that action csv_downloads returns OK' do
      get :csv_download, id: grade_entry_form
      expect(response.status).to eq(200)
    end

    it 'expects a call to send_data' do
      expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.render nothing: true
      }
      get :csv_download, id: grade_entry_form
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :csv_download, id: grade_entry_form
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    # parse header object to check for the right content type
    it 'returns vnd.ms-excel type' do
      get :csv_download, id: grade_entry_form
      expect(response.content_type).to eq 'application/vnd.ms-excel'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get :csv_download, id: grade_entry_form
      filename = response.header['Content-Disposition']
                 .split.last.split('"').second
      expect(filename).to eq "#{grade_entry_form.short_identifier}" +
        '_grades_report.csv'
    end
  end
end
