describe CourseSummariesController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  include CourseSummariesHelper

  context 'An instructor' do
    let(:instructor) { create(:instructor) }
    let(:course) { instructor.course }

    describe '#download_csv_grades_report' do
      it 'be able to get a csv grade report' do
        assignments = create_list(:assignment_with_criteria_and_results, 3)
        create(:grouping_with_inviter_and_submission, assignment: assignments[0])
        create(:grouping_with_inviter, assignment: assignments[0])
        csv_rows = get_as(instructor, :download_csv_grades_report,
                          params: { course_id: course.id }, format: :csv).parsed_body
        expect(csv_rows.size).to eq(Student.count + 2) # one header row, one out of row, plus one row per student
        header = Student::CSV_ORDER.map { |field| User.human_attribute_name(field) }
        assignments.each do |assignment|
          header.push(assignment.short_identifier)
        end
        expect(csv_rows.shift).to eq(header)
        csv_rows.each do |csv_row|
          if csv_row[0] == Assessment.human_attribute_name(:max_mark)
            next
          end
          student_name = csv_row.shift
          # Skipping first/last name, id_number, section and email fields
          (Student::CSV_ORDER.length - 1).times { |_| csv_row.shift }
          student = Student.joins(:user).where('users.user_name': student_name).first
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
              expect(final_mark.to_f.round).to eq(grouping.current_result.get_total_mark.to_f.round)
            end
          end
        end
        expect(response).to have_http_status(:ok)
      end

      context 'tests the second csv row which contains out of values' do
        it 'checks the out of row is numerically and sequentially correct' do
          # this test checks that the following
          # 1) the out_row is the correct length (right amount of assessments included)
          # 2) the order of each assessment in the header corresponds to the right value in the out_of row
          # 3) the values in the out_of row correspond to the CORRECT values of the respective assessments
          assignments = create_list(:assignment_with_criteria_and_results, 3)
          grade_forms = create_list(:grade_entry_form_with_data, 2)
          create(:grouping_with_inviter_and_submission, assignment: assignments[0])
          create(:grouping_with_inviter, assignment: assignments[0])
          csv_rows = get_as(instructor, :download_csv_grades_report,
                            params: { course_id: course.id }, format: :csv).parsed_body
          header = csv_rows[0]
          out_of_row = csv_rows[1]
          expect(out_of_row.size).to eq(Student::CSV_ORDER.length + assignments.size + grade_forms.size)
          expect(out_of_row.size).to eq(header.size)
          zipped_info = Assessment.order(:id).zip(out_of_row[Student::CSV_ORDER.length, out_of_row.size])
          zipped_info.each do |model, out_of_element|
            expect(out_of_element).to eq(model.max_mark.to_s)
          end
        end
      end

      context 'when at least one result is a remark result' do
        it do
          assignment = create(:assignment_with_criteria_and_results_with_remark)
          remark_results = assignment.groupings.map(&:results).group_by(&:count)[2].first
          grouping = remark_results.first.grouping
          user_name = grouping.students.first.user_name
          csv_rows = get_as(instructor, :download_csv_grades_report,
                            params: { course_id: course.id }, format: :csv).parsed_body
          csv_rows.each do |r|
            next if r.first != user_name

            expect(r.last).to eq(grouping.current_result.get_total_mark.to_s)
          end
        end
      end
    end

    describe '#populate' do
      context 'when there are no remark requests' do
        before do
          assignments = create_list(:assignment_with_criteria_and_results, 3)
          create(:grouping_with_inviter_and_submission, assignment: assignments[0])
          create_list(:grade_entry_form_with_data, 2)
          create(:grade_entry_form)
          create(:marking_scheme, assessments: Assessment.all)

          get_as instructor, :populate, params: { course_id: course.id }, format: :json
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
              section_name: student.section_name,
              email: student.email,
              hidden: student.hidden,
              assessment_marks: GradeEntryForm.all.map do |ges|
                total_grade = ges.grade_entry_students.find_by(role: student).get_total_grade
                out_of = ges.grade_entry_items.sum(:out_of)
                percent = total_grade.nil? || out_of.nil? ? nil : (total_grade * 100 / out_of).round(2)
                [ges.id.to_s.to_sym, {
                  mark: total_grade,
                  percentage: percent
                }]
              end.to_h
            }
            student.accepted_groupings.each do |g|
              mark = g.current_result.get_total_mark
              expected[:assessment_marks][g.assessment_id.to_s.to_sym] = {
                mark: mark,
                percentage: (mark * 100 / g.assignment.max_mark).round(2).to_s
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
          Assessment.order(id: :asc).each do |a|
            averages << a.results_average&.round(2)
            medians << a.results_median&.round(2)
          end
          MarkingScheme.find_each do |m|
            total = m.marking_weights.pluck(:weight).compact.sum
            grades = m.students_weighted_grades_array(instructor)
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
          get_as instructor, :populate, params: { course_id: course.id }, format: :json
          data = response.parsed_body.deep_symbolize_keys[:data]
          data.each do |d|
            next if d[:user_name] != user_name

            expect(d[:assessment_marks][assignment.id.to_s.to_sym][:mark]).to eq(grouping.current_result.get_total_mark)
          end
        end
      end

      context 'when there are peer reviews' do
        before do
          assignments = create_list(:assignment_with_criteria_and_results, 3)
          @pr_assignment = create(:assignment_with_peer_review_and_groupings_results,
                                  parent_assessment_id: assignments[0].id)
          create(:complete_result, grouping: @pr_assignment.groupings.first)
          get_as instructor, :populate, params: { course_id: course.id }, format: :json
          @response_data = response.parsed_body.deep_symbolize_keys
          @assessments = @response_data[:assessments]
        end

        it 'does not return the peer review mark' do
          expect(@assessments.pluck(:id)).not_to include @pr_assignment.id # rubocop:disable Rails/PluckId
        end
      end

      context 'when there are percentage extra_marks' do
        before do
          assignments = create_list(:assignment_with_criteria_and_results, 3)
          create(:grouping_with_inviter_and_submission, assignment: assignments[0])
          create_list(:grade_entry_form_with_data, 2)
          create(:grade_entry_form)
          create(:marking_scheme, assessments: Assessment.all)
          assignments.first.criteria.first.update!(max_mark: 3.0)
          assignments.second.criteria.first.update!(max_mark: 2.0)
          assignments.third.criteria.first.update!(max_mark: 5.0)
          assignments.each do |assignment|
            create(:extra_mark, result: assignment.groupings.first.current_result)
          end

          get_as instructor, :populate, params: { course_id: course.id }, format: :json
          @response_data = response.parsed_body.deep_symbolize_keys
          @data = @response_data[:data]
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
              section_name: student.section_name,
              email: student.email,
              hidden: student.hidden,
              assessment_marks: GradeEntryForm.all.map do |ges|
                total_grade = ges.grade_entry_students.find_by(role: student).get_total_grade
                out_of = ges.grade_entry_items.sum(:out_of)
                percent = total_grade.nil? || out_of.nil? ? nil : (total_grade * 100 / out_of).round(2)
                [ges.id.to_s.to_sym, {
                  mark: total_grade,
                  percentage: percent
                }]
              end.to_h
            }
            student.accepted_groupings.each do |g|
              mark = g.current_result.get_total_mark
              expected[:assessment_marks][g.assessment_id.to_s.to_sym] = {
                mark: mark,
                percentage: (mark * 100 / g.assignment.max_mark).round(2).to_s
              }
            end
            expect(@data.map { |h| h.except(:weighted_marks) }).to include expected
          end
        end
      end
    end
  end

  context 'A grader' do
    let(:grader) { create(:ta) }

    it 'not be able to CSV graders report' do
      get_as grader, :download_csv_grades_report, params: { course_id: grader.course.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'A student' do
    let(:student) { create(:student) }
    let(:course) { student.course }

    it 'not be able to access grades report' do
      get_as student, :download_csv_grades_report, params: { course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    describe '#populate' do
      before do
        create_list(:assignment_with_criteria_and_results, 3)
        create_list(:grade_entry_form_with_data, 2)
        create(:marking_scheme, assessments: Assessment.all)
        @student2 = Student.first
      end

      context 'when assessments are hidden' do
        before do
          Assessment.find_each do |a|
            a.update(is_hidden: true)
          end
        end

        it 'displays no information if all assessments are hidden' do
          get_as @student2, :populate, params: { course_id: course.id }, format: :json
          r = response.parsed_body
          expect(r['data'][0]['assessment_marks']).to eq({})
          expect(r['data'][0]['user_name']).to eq @student2.user_name
        end

        it 'displays limited information if only some assessments are hidden' do
          assignment = Assignment.first
          assignment.update(is_hidden: false)
          grouping = assignment.groupings.first
          grouping.current_result.update(released_to_students: true)
          student = grouping.inviter
          gef = GradeEntryForm.first
          gef.update(is_hidden: false)
          expected_assessment_marks = {}
          mark = grouping.current_result.get_total_mark
          expected_assessment_marks[assignment.id.to_s] = {
            'mark' => mark,
            'percentage' => (mark * 100 / grouping.assignment.max_mark).round(2).to_s
          }
          get_as student, :populate, params: { course_id: course.id }, format: :json
          r = response.parsed_body
          expect(r['data'][0]['assessment_marks']).to eq(expected_assessment_marks)
          expect(r['data'][0]['user_name']).to eq student.user_name
        end
      end

      context 'when no marks are released' do
        let(:populate) { get_as @student2, :populate, params: { course_id: course.id }, format: :json }
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
            section_name: @student2.section_name,
            email: @student2.email,
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
            Assessment.order(id: :asc).each do |a|
              averages << a.results_average&.round(2)
              medians << (a.display_median_to_students ? a.results_median&.round(2) : nil)
            end
            expect(returned_medians.compact).to be_empty
            expect(returned_averages.compact).to be_empty
          end
        end

        context 'when there are peer reviews' do
          before do
            assignments = create_list(:assignment_with_criteria_and_results, 3)
            @pr_assignment = create(:assignment_with_peer_review_and_groupings_results,
                                    parent_assessment_id: assignments[0].id)
            create(:complete_result, grouping: @pr_assignment.groupings.first)
            get_as student, :populate, params: { course_id: course.id }, format: :json
            @response_data = response.parsed_body.deep_symbolize_keys
            @assessments = @response_data[:assessments]
          end

          it 'does not return the peer review mark' do
            expect(@assessments.pluck(:id)).not_to include @pr_assignment.id # rubocop:disable Rails/PluckId
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

    describe '#grade_distribution' do
      let(:role) { create(:instructor) }
      let(:course) { role.course }

      before { create(:student, course: course) }

      it('should respond with 200 (ok)') do
        create(:marking_scheme, assessments: Assessment.all)
        get_as role, :grade_distribution, params: { course_id: course.id }, format: :json
        expect(response).to have_http_status :ok
      end

      it 'returns correct data' do
        marking_scheme = create(:marking_scheme, assessments: Assessment.all)
        expected = {}
        expected[:datasets] = [{ data: marking_scheme.students_grade_distribution(role) }]
        expected[:labels] = (0..19).map { |i| "#{5 * i}-#{5 * i + 5}" }
        grades = marking_scheme.students_weighted_grades_array(role)
        expected[:summary] = [{
          average: DescriptiveStatistics.mean(grades),
          median: DescriptiveStatistics.median(grades),
          name: marking_scheme.name
        }]
        get_as role, :grade_distribution, params: { course_id: course.id }, format: :json
        expect(response.parsed_body).to eq expected.as_json
      end

      it 'returns correct data with no marking schemes' do
        get_as role, :grade_distribution, params: { course_id: course.id }, format: :json
        expected = {}
        expected[:datasets] = []
        expected[:labels] = (0..19).map { |i| "#{5 * i}-#{5 * i + 5}" }
        expected[:summary] = []
        expect(response.parsed_body).to eq expected.as_json
      end

      it 'returns correct data when there is multiple marking schemes' do
        marking_schemes = create_list(:marking_scheme, 2, assessments: Assessment.all)
        expected = {}
        expected[:datasets] = marking_schemes.map { |m| { data: m.students_grade_distribution(role) } }
        expected[:labels] = (0..19).map { |i| "#{5 * i}-#{5 * i + 5}" }
        grades = marking_schemes.map { |m| m.students_weighted_grades_array(role) }
        expected[:summary] = marking_schemes.zip(grades).map do |marking_scheme, grade|
          {
            average: DescriptiveStatistics.mean(grade),
            median: DescriptiveStatistics.median(grade),
            name: marking_scheme.name
          }
        end
        get_as role, :grade_distribution, params: { course_id: course.id }, format: :json
        expect(response.parsed_body).to eq expected.as_json
      end
    end
  end
end
