describe CourseSummariesController do

  context 'An admin' do
    before do
      @admin = Admin.create(user_name: 'adoe',
                            last_name: 'doe',
                            first_name: 'adam')
    end

    describe '#download_csv_grades_report' do
      before :each do
        3.times { create(:assignment_with_criteria_and_results) }
      end

      it 'be able to get a csv grade report' do
        csv_rows = get_as(@admin, :download_csv_grades_report, format: :csv).parsed_body
        expect(csv_rows.size).to eq(Student.count + 1) # one header row plus one row per student

        assignments = Assignment.all.order(id: :asc)
        header = [User.human_attribute_name(:user_name),
                  User.human_attribute_name(:first_name),
                  User.human_attribute_name(:last_name),
                  User.human_attribute_name(:id_number)]
        assignments.each do |assignment|
          header.push(assignment.short_identifier)
        end
        expect(csv_rows.shift).to eq(header)
        csv_rows.each do |csv_row|
          student_name = csv_row.shift
          # Skipping first/last name and id_number fields
          3.times { |_| csv_row.shift }
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
              grouping = student.accepted_grouping_for(assignments[index])
              expect(final_mark.to_f.round).to eq(grouping.current_result.total_mark.to_f.round)
            end
          end
        end
        expect(response.status).to eq(200)
      end
    end

    describe '#populate' do
      before :each do
        3.times { create(:assignment_with_criteria_and_results) }
        2.times { create(:grade_entry_form_with_data) }
        # TODO: Create marking scheme as well

        get_as @admin, :populate, format: :json
        response_data = response.parsed_body.deep_symbolize_keys
        @assessment_info = response_data[:assessment_info]
        @columns = response_data[:columns]
        @data = response_data[:data]
      end

      it 'returns the correct columns' do
        expect(@columns.length).to eq(Assignment.count + GradeEntryForm.count)
        Assessment.find_each do |a|
          expected = {
            accessor: "assessment_marks.#{a.id}.mark",
            Header: a.short_identifier,
            minWidth: 50,
            className: 'number',
            headerStyle: { textAlign: 'right' }
          }
          expect(@columns).to include expected
        end
      end

      it 'returns the correct grades' do
        expect(@data.length).to eq Student.count
        Student.find_each do |student|
          expected = {
            id: student.id,
            id_number: student.id_number,
            user_name: student.user_name,
            first_name: student.first_name,
            last_name: student.last_name,
            hidden: student.hidden,
            assessment_marks: Hash[GradeEntryForm.all.map do |ges|
              [ges.id.to_s.to_sym, {
                mark: ges.grade_entry_students.find_by(user: student).total_grade,
                percentage: (ges.grade_entry_students
                                .find_by(user: student).total_grade * 100 / ges.grade_entry_items.sum(:out_of)).round(2)
              }]
            end
            ]
          }
          student.accepted_groupings.each do |g|
            expected[:assessment_marks][g.assessment_id.to_s.to_sym] = {
              mark: g.current_result.total_mark,
              percentage: (g.current_result.total_mark * 100 / g.assignment.max_mark).round(2).to_s
            }
          end
          expect(@data).to include expected
        end
      end

      it 'returns correct average, median, and total info about assessments' do
        totals = []
        averages = []
        medians = []
        returned_averages = []
        returned_totals = []
        returned_medians = []
        Assessment.all.order(id: :asc).each do |a|
          returned_averages << @assessment_info[a.short_identifier.to_sym][:average]
          returned_medians << @assessment_info[a.short_identifier.to_sym][:median]
          returned_totals << @assessment_info[a.short_identifier.to_sym][:total]
          if a.is_a? GradeEntryForm
            totals << a.grade_entry_items.sum(:out_of)
            averages << a.calculate_average&.round(2)
            medians << a.calculate_median&.round(2)
          else
            totals << a.max_mark.to_s
            averages << a.results_average&.round(2)
            medians << a.results_median&.round(2)
          end
        end
        expect(returned_totals).to eq totals
        expect(returned_medians).to eq medians
        expect(returned_averages).to eq averages
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

    describe '#populate' do
      before :each do
        3.times { create(:assignment_with_criteria_and_results) }
        2.times { create(:grade_entry_form_with_data) }
        # TODO: Create marking scheme as well

        @student2 = Student.first
      end
      context 'when assessments are hidden' do
        before :each do
          Assessment.all.each do |a|
            a.update(is_hidden: true)
          end
        end

        it 'displays no information if all assessments are hidden' do
          get_as @student2, :populate, format: :json
          r = response.parsed_body
          expect(r['columns']).to eq []
          expect(r['assessment_info']).to eq({})
          expect(r['data'][0]['assessment_marks']).to eq({})
          expect(r['data'][0]['user_name']).to eq @student2.user_name
        end

        it 'displays limited information if only some assessments are hidden' do
          assignment = Assignment.all.first
          assignment.update(is_hidden: false)
          grouping = assignment.groupings.first
          grouping.current_result.update(released_to_students: true)
          student = grouping.inviter
          gef = GradeEntryForm.all.first
          gef.update(is_hidden: false)
          averages = [gef.calculate_average&.round(2), assignment.results_average&.round(2)].sort!
          expected_assessment_marks = {}
          expected_assessment_marks[assignment.id.to_s] = {
            'mark' => grouping.current_result.total_mark,
            'percentage' => (grouping.current_result.total_mark * 100 / grouping.assignment.max_mark).round(2).to_s
          }
          get_as student, :populate, format: :json
          r = response.parsed_body
          expect(r['columns'].length).to eq 2
          expect(r['assessment_info'].map { |a| a[1]['average'] }.sort!).to eq(averages)
          expect(r['assessment_info'].map { |a| a[1]['total'].to_f }.sort!).to eq [assignment.max_mark.to_f,
                                                                                   gef.grade_entry_items
                                                                                      .sum(:out_of)].sort!
          expect(r['assessment_info'].map { |a| a[1]['median'] }).to eq [nil, nil]
          expect(r['data'][0]['assessment_marks']).to eq(expected_assessment_marks)
          expect(r['data'][0]['user_name']).to eq student.user_name
        end
      end
      context 'when no marks are released' do
        before :each do
          get_as @student2, :populate, format: :json
          response_data = response.parsed_body.deep_symbolize_keys
          @assessment_info = response_data[:assessment_info]
          @columns = response_data[:columns]
          @data = response_data[:data]
        end
        it 'returns the correct columns' do
          expect(@columns.length).to eq(Assignment.count + GradeEntryForm.count)
          Assessment.find_each do |a|
            expected = {
              accessor: "assessment_marks.#{a.id}.mark",
              Header: a.short_identifier,
              minWidth: 50,
              className: 'number',
              headerStyle: { textAlign: 'right' }
            }
            expect(@columns).to include expected
          end
        end

        it 'returns no grades for the student' do
          expect(@data.length).to eq 1
          expected = {
            id: @student2.id,
            id_number: @student2.id_number,
            user_name: @student2.user_name,
            first_name: @student2.first_name,
            last_name: @student2.last_name,
            hidden: @student2.hidden,
            assessment_marks: {}
          }
          expect(@data).to include expected
        end

        it 'returns correct average, median, and total info about assessments' do
          totals = []
          averages = []
          medians = []
          returned_averages = []
          returned_totals = []
          returned_medians = []
          Assessment.all.order(id: :asc).each do |a|
            returned_averages << @assessment_info[a.short_identifier.to_sym][:average]
            returned_medians << @assessment_info[a.short_identifier.to_sym][:median]
            returned_totals << @assessment_info[a.short_identifier.to_sym][:total]
            medians << nil
            if a.is_a? GradeEntryForm
              totals << a.grade_entry_items.sum(:out_of)
              averages << a.calculate_average&.round(2)
            else
              totals << a.max_mark.to_s
              averages << a.results_average&.round(2)
            end
          end
          expect(returned_totals).to eq totals
          expect(returned_medians).to eq medians
          expect(returned_averages).to eq averages
        end
      end
    end
  end
end
