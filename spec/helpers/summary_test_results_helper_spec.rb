describe SummaryTestResultsHelper do
  describe SummaryTestResultsHelper::SummaryTestResults do
    context 'an assignment with no test results' do
      let(:assignment) { create(:assignment_with_criteria_and_results) }

      it 'should return {} when using json' do
        expect(SummaryTestResultsHelper::SummaryTestResults.fetch(
          test_groups: assignment.test_groups,
          latest: true,
          student_run: true,
          instructor_run: false
        ).as_json).to eq('{}')
      end

      it 'should be empty when using csv' do
        expect(SummaryTestResultsHelper::SummaryTestResults.fetch(
          test_groups: assignment.test_groups,
          latest: true,
          student_run: true,
          instructor_run: false
        ).as_csv).to eq("\n")
      end
    end

    context 'an assignment with test results across multiple test groups' do
      let(:assignment) { create(:assignment_with_criteria_and_test_results) }

      it 'has the correct group and test names' do
        expect(assignment.test_groups.size).to be > 1

        summary_test_results = JSON.parse(SummaryTestResultsHelper::SummaryTestResults.fetch(
          test_groups: assignment.test_groups,
          latest: true,
          student_run: true,
          instructor_run: false
        ).as_json)

        summary_test_results.map do |group_name, group|
          group.map do |test_group_name, test_group|
            test_group.each do |test_result|
              expect(test_result.fetch('name')).to eq test_group_name
              expect(test_result.fetch('group_name')).to eq group_name
              expect(test_result.key?('status')).to be true
            end
          end
        end
      end

      it 'has the correct test result keys' do
        expect(assignment.test_groups.size).to be > 1

        summary_test_results = JSON.parse(SummaryTestResultsHelper::SummaryTestResults.fetch(
          test_groups: assignment.test_groups,
          latest: true,
          student_run: true,
          instructor_run: false
        ).as_json)

        expected_keys = %w[marks_earned
                           marks_total
                           output
                           name
                           test_result_name
                           test_groups_id
                           group_name
                           status
                           extra_info
                           error_type
                           id]
        summary_test_results.map do |_, group|
          group.map do |_, test_group|
            test_group.each do |test_result|
              expect(test_result.keys).to match_array expected_keys
            end
          end
        end
      end

      # despite having multiple test groups, assignment is set up so every test
      # run contains results from exactly one test group; so this should also
      # return results from only one test group
      it 'returns results from only one test group for each group when fetching latest results' do
        expect(assignment.test_groups.size).to be > 1

        summary_test_results = JSON.parse(SummaryTestResultsHelper::SummaryTestResults.fetch(
          test_groups: assignment.test_groups,
          latest: true,
          student_run: true,
          instructor_run: false
        ).as_json)

        summary_test_results.map do |_group_name, group|
          expect(group.count).to eq 1
        end
      end

      it 'returns results from more than one test group for each group when not fetching latest results' do
        expect(assignment.test_groups.size).to be > 1

        summary_test_results = JSON.parse(SummaryTestResultsHelper::SummaryTestResults.fetch(
          test_groups: assignment.test_groups,
          latest: false,
          student_run: true,
          instructor_run: false
        ).as_json)

        summary_test_results.map do |_group_name, group|
          expect(group.count).to be > 1
        end
      end
    end
  end
end
