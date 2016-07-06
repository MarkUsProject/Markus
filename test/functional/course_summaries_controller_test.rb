require 'shoulda'

class CourseSummariesControllerTest < AuthenticatedControllerTest
  def setup
    @controller = CourseSummariesController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def teardown
    destroy_repos
  end

  context 'An admin' do
    setup do
      @admin = Admin.make
    end

    context 'with an assignment' do
      setup do
        @assignment = Assignment.make
      end

      should 'be able to get a csv grade report' do
        response_csv = get_as(@admin, :download_csv_grades_report).body
        csv_rows = CSV.parse(response_csv)
        assert_equal Student.all.size + 1, csv_rows.size # for header
        assignments = Assignment.order(:id)
        header = ['Username']
        assignments.each do |assignment|
          header.push(assignment.short_identifier)
        end
        assert_equal csv_rows.shift, header
        csv_rows.each do |csv_row|
          student_name = csv_row.shift
          student = Student.find_by_user_name(student_name)
          assert_not_nil student
          assert_equal assignments.size, csv_row.size

          csv_row.each_with_index do |final_mark, index|
            if final_mark.blank?
              if student.has_accepted_grouping_for?(assignments[index])
                grouping = student.accepted_grouping_for(assignments[index])
                assert (!grouping.has_submission? ||
                           assignments[index].max_mark == 0)
              end
            else
              out_of = assignments[index].max_mark
              grouping = student.accepted_grouping_for(assignments[index])
              assert_not_nil grouping
              assert grouping.has_submission?
              submission = grouping.current_submission_used
              assert_not_nil submission.get_latest_result
              assert_equal final_mark.to_f.round,
                           (submission.get_latest_result.total_mark / out_of *
                            100).to_f.round
            end
          end
        end
        assert_response :success
      end
    end
  end

  context 'A grader' do
    setup do
      @grader = Ta.make
    end

    should 'not be able to CSV graders report' do
      get_as @grader, :download_csv_grades_report
      assert_response :missing
    end
  end

  context 'A student' do
    setup do
      @student = Student.make
    end

    should 'not be able to access grades report' do
      get_as @student, :download_csv_grades_report
      assert_response :missing
    end
  end
end

