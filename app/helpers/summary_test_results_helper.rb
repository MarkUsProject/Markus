module SummaryTestResultsHelper
  class SummaryTestResults
    class << self
      def fetch(test_groups:, latest:, student_run:, instructor_run:)
        query = base_query(latest:)

        query = query.student_run if student_run && !instructor_run
        query = query.instructor_run if !student_run && instructor_run

        test_results = fetch_with_query(test_groups:, query:)

        SummaryTestResult.new(test_results:)
      end

      private

      def base_query(latest:)
        if latest
          TestRun.group('grouping_id').select('MAX(created_at) as test_runs_created_at', 'grouping_id')
        else
          TestRun.select('created_at as test_runs_created_at', 'grouping_id')
        end
      end

      def fetch_with_query(test_groups:, query:)
        latest_test_runs = TestRun
                           .joins(grouping: :group)
                           .joins("INNER JOIN (#{query.to_sql}) latest_test_run_by_grouping \
            ON latest_test_run_by_grouping.grouping_id = test_runs.grouping_id \
            AND latest_test_run_by_grouping.test_runs_created_at = test_runs.created_at")
                           .select('id', 'test_runs.grouping_id', 'groups.group_name')
                           .to_sql

        test_groups.joins(test_group_results: :test_results)
                   .joins("INNER JOIN (#{latest_test_runs}) latest_test_runs \
              ON test_group_results.test_run_id = latest_test_runs.id")
                   .select('test_groups.name',
                           'test_groups.id as test_groups_id',
                           'latest_test_runs.group_name',
                           'test_results.name as test_result_name',
                           'test_results.status',
                           'test_results.marks_earned',
                           'test_results.marks_total',
                           :output, :extra_info, :error_type)
      end
    end
  end

  class SummaryTestResult
    def initialize(test_results:)
      @test_results = test_results
    end

    def as_csv
      results = {}
      headers = Set.new

      summary_test_results = @test_results.as_json

      summary_test_results.each do |test_result|
        header = "#{test_result['name']}:#{test_result['test_result_name']}"

        if results.key?(test_result['group_name'])
          results[test_result['group_name']][header] = test_result['status']
        else
          results[test_result['group_name']] = { header => test_result['status'] }
        end

        headers << header
      end
      headers = headers.sort

      CSV.generate do |csv|
        csv << [nil, *headers]

        results.sort_by(&:first).each do |(group_name, _test_group)|
          row = [group_name]

          headers.each do |header|
            if results[group_name].key?(header)
              row << results[group_name][header]
            else
              row << nil
            end
          end
          csv << row
        end
      end
    end

    def as_json
      @test_results.group_by(&:group_name).transform_values do |grouping|
        grouping.group_by(&:name)
      end.to_json
    end
  end
end
