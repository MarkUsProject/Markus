require File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

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
        get_as @user, :index, grade_entry_form_id: @grade_entry_form.id
        assert_response :missing
      end

      should "fail to GET :populate as a #{user_type}" do
        get_as @user, :populate, grade_entry_form_id: @grade_entry_form.id
        assert_response :missing
      end

      should "fail to POST to :global_actions as a #{user_type}" do
        post_as @user, :global_actions, grade_entry_form_id: @grade_entry_form.id
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
        s = Student.make
        @students << s
        @graders << Ta.make
      end
    end

    should 'see the "Manage Graders" page on GET :index' do
      get_as @admin, :index, grade_entry_form_id: @grade_entry_form.id
      assert_response :success
      assert @response.body.include?('Manage Graders')
      assert @response.body.include?('Download')
      assert @response.body.include?('Upload')
    end

    should 'receive a list of students on POST :populate' do
      get_as @admin, :populate, grade_entry_form_id: @grade_entry_form.id
      assert_response :success
      @students.each { |student| assert @response.body.include?(student.user_name) }
    end

    should 'redirect to :index on POST :csv_upload_grader_groups_mapping' do
      post_as @admin, :csv_upload_grader_groups_mapping,
        grade_entry_form_id: @grade_entry_form.id
      assert_response 302
      assert_redirected_to(action: 'index')
    end

    should 'see an error on POST :csv_upload_grader_groups_mapping with no file' do
      post_as @admin, :csv_upload_grader_groups_mapping,
        grade_entry_form_id: @grade_entry_form.id
      assert_response 302
      assert_redirected_to(action: 'index')
      assert_equal [I18n.t('csv.student_to_grader')], flash[:error]
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
        grade_entry_form_id: @grade_entry_form.id,
        grader_mapping: Rack::Test::UploadedFile.new(file.path, 'text/csv')
      assert_nil flash[:error]
      assert_redirected_to(action: 'index')

      [0, 1].each do |i|
        assert_equal 1, @graders[i].get_membership_count_by_grade_entry_form(@grade_entry_form)
      end
    end

    should 'download a csv on GET :download_grader_students_mapping' do
      entry_students = @grade_entry_form.grade_entry_students
      entry_student = entry_students.find_or_create_by(
        user_id: @students[0].id)
      entry_student.add_tas([@graders[0], @graders[1]])

      # Build expected csv output
      csv = "#{@students[0].user_name},#{@graders[0].user_name},#{@graders[1].user_name}\n"
      (1..4).each do |i|
        csv += "#{@students[i].user_name}\n"
      end

      get_as @admin, :download_grader_students_mapping,
        grade_entry_form_id: @grade_entry_form.id
      assert_response :success
      assert_equal CSV.parse(csv).to_set, CSV.parse(@response.body).to_set
    end

    should 'be able to assign a grader to a student on POST :global_actions' do
      post_as @admin, :global_actions, { grade_entry_form_id: @grade_entry_form.id,
        global_actions: 'assign', students: [@students[0]],
        graders: [@graders[0]], submit_type: 'global_action',
        current_table: 'groups_table' }

      assert_nil flash[:error]
      assert_equal 1, @graders[0].get_membership_count_by_grade_entry_form(@grade_entry_form)
      assert_equal 1, @grade_entry_form.grade_entry_students.find_by_user_id(@students[0].id).tas.length
    end

    should 'be able to assign multiple graders to students on POST :global_actions' do
      post_as @admin, :global_actions, { grade_entry_form_id: @grade_entry_form.id,
        global_actions: 'assign', students: [@students[0], @students[1]],
        graders: [@graders[0], @graders[1]], submit_type: 'global_action',
        current_table: 'groups_table' }

      entry_students = @grade_entry_form.grade_entry_students

      assert_nil flash[:error]
      assert_equal 2, @graders[0].get_membership_count_by_grade_entry_form(@grade_entry_form)
      assert_equal 2, @graders[1].get_membership_count_by_grade_entry_form(@grade_entry_form)
      assert_equal 2, entry_students.find_by_user_id(@students[0].id).tas.length
      assert_equal 2, entry_students.find_by_user_id(@students[0].id).tas.length
    end

    should 'be able to randomly and evenly assign graders to students on POST :global_actions' do
      post_as @admin, :global_actions, { grade_entry_form_id: @grade_entry_form.id,
        global_actions: 'random_assign', students: [@students[0], @students[1]],
        graders: [@graders[0], @graders[1]], submit_type: 'global_action',
        current_table: 'groups_table' }

      entry_students = @grade_entry_form.grade_entry_students

      assert_nil flash[:error]
      assert_equal 1, @graders[0].get_membership_count_by_grade_entry_form(@grade_entry_form)
      assert_equal 1, @graders[1].get_membership_count_by_grade_entry_form(@grade_entry_form)
      assert_equal 1, entry_students.find_by_user_id(@students[0].id).tas.length
      assert_equal 1, entry_students.find_by_user_id(@students[0].id).tas.length
    end

    should 'be able to remove a grader from a student on POST :global_actions' do
      # Add a grader to a student
      entry_students = @grade_entry_form.grade_entry_students
      grade_entry_student = entry_students.find_or_create_by(
        user_id: @students[0].id)
      grade_entry_student.add_tas(@graders[0])
      gest_ids = grade_entry_student.grade_entry_student_tas.pluck(:id)

      remove = "#{@students[0].id}_#{@graders[0].user_name}".to_sym
      post_as @admin, :global_actions,
              grade_entry_form_id: @grade_entry_form.id,
              global_actions: 'unassign',
              students: [@students[0]],
              submit_type: 'global_action',
              current_table: 'groups_table',
              gests: gest_ids

      assert_nil flash[:error]
      assert_equal 0, @graders[0].get_membership_count_by_grade_entry_form(@grade_entry_form)
      assert_equal 0, entry_students.find_by_user_id(@students[0].id).tas.length
    end

    should 'gracefully handle malformed csv files' do
      tempfile = fixture_file_upload('files/malformed.csv')
      post_as @admin,
              :csv_upload_grader_groups_mapping,
              grade_entry_form_id: @grade_entry_form.id,
              grader_mapping: tempfile

      assert_response :redirect
      assert_equal flash[:error], [I18n.t('csv.upload.malformed_csv')]
    end

    should 'gracefully handle a non csv file with a csv extension' do
      tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
      post_as @admin,
              :csv_upload_grader_groups_mapping,
              grade_entry_form_id: @grade_entry_form.id,
              grader_mapping: tempfile,
              encoding: 'UTF-8'

      assert_response :redirect
      assert_equal flash[:error],
                   [I18n.t('csv.upload.non_text_file_with_csv_extension')]
    end
  end # admin context
end
