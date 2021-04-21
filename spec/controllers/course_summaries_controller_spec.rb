describe CourseSummariesController do
  include CourseSummariesHelper
  context 'An admin' do
    before do
      @admin = Admin.create(user_name: 'adoe',
                            last_name: 'doe',
                            first_name: 'adam')
    end

    describe '#download_csv_grades_report' do
      it 'be able to get a csv grade report' do
        assignments = create_list(:assignment_with_criteria_and_results, 3)
        create(:grouping_with_inviter_and_submission, assignment: assignments[0])
        create(:grouping_with_inviter, assignment: assignments[0])
        csv_rows = get_as(@admin, :download_csv_grades_report, format: :csv).parsed_body
        expect(csv_rows.size).to eq(Student.count + 1) # one header row plus one row per student

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
      context 'when at least one result is a remark result' do
        it do
          assignment = create(:assignment_with_criteria_and_results_with_remark)
          remark_results = assignment.groupings.map(&:results).group_by(&:count)[2].first
          grouping = remark_results.first.grouping
          user_name = grouping.students.first.user_name
          csv_rows = get_as(@admin, :download_csv_grades_report, format: :csv).parsed_body
          csv_rows.select { |r| r.first == user_name }
                  .map { |r| expect(r.last).to eq(grouping.current_result.total_mark.to_s) }
        end
      end
    end

    describe '#populate' do
      context 'when there are no remark requests' do
        before :each do
          assignments = create_list(:assignment_with_criteria_and_results, 3)
          create(:grouping_with_inviter_and_submission, assignment: assignments[0])
          2.times { create(:grade_entry_form_with_data) }
          create(:grade_entry_form)
          create :marking_scheme, assessments: Assessment.all

          get_as @admin, :populate, format: :json
          @response_data = response.parsed_body.deep_symbolize_keys
          @data = @response_data[:data]
        end

        it 'displays column headers correctly' do
          expect(@response_data[:assessments][0][:name]).to eq('A1 (/3.0)')
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
                total_grade = ges.grade_entry_students.find_by(user: student).total_grade
                out_of = ges.grade_entry_items.sum(:out_of)
                percent = total_grade.nil? || out_of.nil? ? nil : (total_grade * 100 / out_of).round(2)
                [ges.id.to_s.to_sym, {
                  mark: total_grade,
                  percentage: percent
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
            expect(@data.map { |h| h.except(:weighted_marks) }).to include expected
          end
        end

        it 'returns correct average, median info about assessments' do
          averages = []
          medians = []
          returned_averages = @response_data[:graph_data][:average]
          returned_medians = @response_data[:graph_data][:median]
          Assessment.all.order(id: :asc).each do |a|
            averages << a.results_average&.round(2)
            medians << a.results_median&.round(2)
          end
          MarkingScheme.all.each do |m|
            total = m.marking_weights.pluck(:weight).compact.sum
            grades = m.students_weighted_grades_array(@admin)
            averages << (DescriptiveStatistics.mean(grades) * 100 / total).round(2).to_f
            medians << (DescriptiveStatistics.median(grades) * 100 / total).round(2).to_f
          end
          expect(returned_medians).to eq medians
          expect(returned_averages).to eq averages
        end
      end
      context 'when at least one result is a remark result' do
        it do
          assignment = create(:assignment_with_criteria_and_results_with_remark)
          remark_results = assignment.groupings.map(&:results).group_by(&:count)[2].first
          grouping = remark_results.first.grouping
          user_name = grouping.students.first.user_name
          get_as @admin, :populate, format: :json
          data = response.parsed_body.deep_symbolize_keys[:data]
          data.select { |d| d[:user_name] == user_name }.map do |d|
            expect(d[:assessment_marks][assignment.id.to_s.to_sym][:mark]).to eq(grouping.current_result.total_mark)
          end
        end
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
      expect(response).to have_http_status(403)
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
      expect(response).to have_http_status(403)
    end

    describe '#populate' do
      before :each do
        3.times { create(:assignment_with_criteria_and_results) }
        2.times { create(:grade_entry_form_with_data) }
        create :marking_scheme, assessments: Assessment.all
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
          averages = [nil, assignment.results_average&.round(2)]
          expected_assessment_marks = {}
          expected_assessment_marks[assignment.id.to_s] = {
            'mark' => grouping.current_result.total_mark,
            'percentage' => (grouping.current_result.total_mark * 100 / grouping.assignment.max_mark).round(2).to_s
          }
          get_as student, :populate, format: :json
          r = response.parsed_body
          expect(r['data'][0]['assessment_marks']).to eq(expected_assessment_marks)
          expect(r['data'][0]['user_name']).to eq student.user_name
        end
      end
      context 'when no marks are released' do
        let(:populate) { get_as @student2, :populate, format: :json }
        let(:response_data) { response.parsed_body.deep_symbolize_keys }
        let(:data) { response_data[:data] }

        it 'returns no grades for the student' do
          populate
          expect(data.length).to eq 1
          expected = {
            id: @student2.id,
            id_number: @student2.id_number,
            user_name: @student2.user_name,
            first_name: @student2.first_name,
            last_name: @student2.last_name,
            hidden: @student2.hidden,
            assessment_marks: {}
          }
          expect(data).to include expected
        end

        shared_examples 'check_graph_data' do
          it 'returns correct average, median info about assessments' do
            populate
            averages = []
            medians = []
            returned_averages = response_data[:graph_data][:average]
            returned_medians = response_data[:graph_data][:median]
            Assessment.all.order(id: :asc).each do |a|
              averages << a.results_average&.round(2)
              medians << (a.display_median_to_students ? a.results_median&.round(2) : nil)
            end
            expect(returned_medians.compact).to be_empty
            expect(returned_averages.compact).to be_empty
          end
        end

        context 'when display_median_to_students not set for any assignment' do
          it_behaves_like 'check_graph_data'
        end
        context 'when display_median_to_students set for some assignments' do
          before { Assignment.order(id: :asc).first.assignment_properties.update(display_median_to_students: true) }
          it_behaves_like 'check_graph_data'
        end
      end
    end
  end
end
