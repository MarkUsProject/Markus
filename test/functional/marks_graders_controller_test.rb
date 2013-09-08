require File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

include CsvHelper

require 'shoulda'
require 'mocha/setup'

class MarksGradersControllerTest < AuthenticatedControllerTest
  # Test that graders and students can't access this feature
  context 'An authenticated user making a request' do
    users = { 'Student' => Student, 'Ta' => Ta }
    users.each do |user_type, user_class|
      setup do
        @user = user_class.make
        @grade_entry_form = GradeEntryForm.make
      end

      should "fail to GET :index as a #{user_type}" do
        get_as @user, :index, :grade_entry_form_id => @grade_entry_form.id
        assert_response :missing
      end

      should "fail to GET :upload_dialog as a #{user_type}" do
        get_as @user, :upload_dialog, :grade_entry_form_id => @grade_entry_form.id
        assert_response :missing
      end

      should "fail to GET :download_dialog as a #{user_type}" do
        get_as @user, :download_dialog, :grade_entry_form_id => @grade_entry_form.id
        assert_response :missing
      end

      should "fail to GET :populate as a #{user_type}" do
        get_as @user, :populate, :grade_entry_form_id => @grade_entry_form.id
        assert_response :missing
      end

      should "fail to POST to :global_actions as a #{user_type}" do
        post_as @user, :global_actions, :grade_entry_form_id => @grade_entry_form.id
        assert_response :missing
      end
    end
  end # non-admin context

  context 'An authenticated admin' do
    setup do
      @admin = Admin.make
      @grade_entry_form = GradeEntryForm.make

      @students = []
      @graders = []

      5.times do
        @students << Student.make
        @graders << Ta.make
      end
    end

    should 'see the "Manage Graders" page on GET :index' do
      get_as @admin, :index, :grade_entry_form_id => @grade_entry_form.id
      assert_response :success
      assert @response.body.include?('Manage Graders')
      assert @response.body.include?('Download')
      assert @response.body.include?('Upload')
    end

    should 'see the upload dialog on GET :upload_dialog' do
      get_as @admin, :upload_dialog, :grade_entry_form_id => @grade_entry_form.id
      assert_response :success
      assert_template :partial => 'marks_graders/modal_dialogs/_upload_dialog'
      assert_template :partial => 'marks_graders/modal_dialogs/_upload'
      assert @response.body.include?(I18n.t('marks_graders.upload.upload_grader_map'))
    end

    should 'see the download dialog on GET :download_dialog' do
      get_as @admin, :download_dialog, :grade_entry_form_id => @grade_entry_form.id
      assert_response :success
      assert_template :partial => 'marks_graders/modal_dialogs/_download_dialog'
      assert_template :partial => 'marks_graders/modal_dialogs/_download'
      assert @response.body.include?(I18n.t('groups.download.download_grader_maps'))
    end

    should 'receive a list of students on POST :populate' do
      get_as @admin, :populate, :grade_entry_form_id => @grade_entry_form.id
      assert_response :success
      assert_template :partial => 'marks_graders/table_row/_filter_table_row'
      @students.each { |student| assert @response.body.include?(student.user_name) }
    end

    should 'redirect to :index on POST :csv_upload_grader_groups_mapping' do
      post_as @admin, :csv_upload_grader_groups_mapping,
        :grade_entry_form_id => @grade_entry_form.id
      assert_response 302
      assert_redirected_to(:action => 'index')
    end

    should 'see an error on POST :csv_upload_grader_groups_mapping with no file' do
      post_as @admin, :csv_upload_grader_groups_mapping,
        :grade_entry_form_id => @grade_entry_form.id
      assert_response 302
      assert_redirected_to(:action => 'index')
      assert_equal I18n.t('csv.student_to_grader'), flash[:error]
    end

    should 'map graders on POST :csv_upload_grader_groups_mapping' do
      # Build csv
      csv = "#{@students[0].user_name},#{@graders[0].user_name},#{@graders[1].user_name}\n"
      (1..4).each do |i|
        csv += "#{@students[i].user_name}\n"
      end

      file = Tempfile.new(['mapping_test', '.csv'])
      file.write(csv)
      file.rewind

      post_as @admin, :csv_upload_grader_groups_mapping,
        :grade_entry_form_id => @grade_entry_form.id,
        :grader_mapping => Rack::Test::UploadedFile.new(file.path, 'text/csv')
      assert_nil flash[:error]
      assert_redirected_to(:action => 'index')

      [0, 1].each do |i|
        assert_equal 1, @graders[i].get_membership_count_by_grade_entry_form(@grade_entry_form)
      end
    end

    should 'download a csv on GET :download_grader_students_mapping' do
      entry_students = @grade_entry_form.grade_entry_students
      entry_student  = entry_students.find_or_create_by_user_id(@students[0].id)
      entry_student.add_tas([@graders[0], @graders[1]])

      # Build expected csv output
      csv = "#{@students[0].user_name},#{@graders[0].user_name},#{@graders[1].user_name}\n"
      (1..4).each do |i|
        csv += "#{@students[i].user_name}\n"
      end

      get_as @admin, :download_grader_students_mapping,
        :grade_entry_form_id => @grade_entry_form.id
      assert_response :success
      assert_equal csv, @response.body
    end
  end # admin context
end
