describe CourseSummariesController do

  context 'An admin' do
    before do
      @admin = Admin.create(user_name: 'adoe',
                            last_name: 'doe',
                            first_name: 'adam')
    end

    context 'with an assignment' do
      let(:assignment) { FactoryBot.create(:assignment) }

      it 'be able to get a csv grade report' do
        response_csv = get_as(@admin, :download_csv_grades_report).body
        csv_rows = CSV.parse(response_csv)
        expect(Student.all.size + 1).to eq(csv_rows.size) # for header
        assignments = Assignment.order(:id)
        header = [User.human_attribute_name(:user_name), User.human_attribute_name(:id_number)]
        assignments.each do |assignment|
          header.push(assignment.short_identifier)
        end
        expect(csv_rows.shift).to eq(header)
        csv_rows.each do |csv_row|
          student_name = csv_row.shift
          # Skipping id_number field
          csv_row.shift
          student = Student.find_by_user_name(student_name)
          expect(student).to be_truthy
          expect(assignments.size).to eq(csv_row.size)

          csv_row.each_with_index do |final_mark, index|
            if final_mark.blank?
              if student.has_accepted_grouping_for?(assignments[index])
                grouping = student.accepted_grouping_for(assignments[index])
                expect(!grouping.has_submission? ||
                  assignments[index].max_mark == 0).to be_truthy
              end
            else
              out_of = assignments[index].max_mark
              grouping = student.accepted_grouping_for(assignments[index])
              expect(grouping).to be_truthy
              expect(grouping.has_submission?).to be_truthy
              submission = grouping.current_submission_used
              expect(submission.get_latest_result).to be_truthy
              expect(final_mark.to_f.round).to eq((submission.get_latest_result.total_mark / out_of *
                100).to_f.round)
            end
          end
        end
        expect(response.status).to eq(200)
      end
    end
  end

  context 'A grader' do
    before do
      @grader = Ta.create(user_name: 'adoe',
                          last_name: 'doe',
                          first_name: 'adam')
    end

    it 'not be able to CSV graders report' do
      get_as @grader, :download_csv_grades_report
      expect(response.status).to eq(404)
    end
  end

  context 'A student' do
    before do
      @student = Student.create(user_name: 'adoe',
                                last_name: 'doe',
                                first_name: 'adam')
    end

    it 'not be able to access grades report' do
      get_as @student, :download_csv_grades_report
      expect(response.status).to eq(404)
    end
  end
end
