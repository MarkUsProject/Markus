describe TestRun do
  it { is_expected.to have_many(:test_group_results) }
  it { is_expected.to belong_to(:test_batch).optional }
  it { is_expected.to belong_to(:submission).optional }
  it { is_expected.to belong_to(:grouping) }
  it { is_expected.to belong_to(:user) }

  describe '#cancel' do
    before { test_run.cancel }
    context 'is in progress' do
      let(:test_run) { create :test_run, status: :in_progress }
      it 'should update the status to cancelled' do
        expect(test_run.reload.status).to eq('cancelled')
      end
    end
    context 'is not in progress' do
      let(:test_run) { create :test_run }
      it 'should not update the status to cancelled' do
        expect(test_run.reload.status).to eq('complete')
      end
    end
  end
  describe '#failure' do
    let(:problems) { 'some problem' }
    before { test_run.failure(problems) }
    context 'is in progress' do
      let(:test_run) { create :test_run, status: :in_progress }
      it 'should update the status to cancelled' do
        expect(test_run.reload.status).to eq('failed')
      end
    end
    context 'is not in progress' do
      let(:test_run) { create :test_run }
      it 'should not update the status to cancelled' do
        expect(test_run.reload.status).to eq('complete')
      end
    end
  end
  describe '.all_test_categories' do
    it 'should return [admin, student]' do
      expect(TestRun.all_test_categories).to contain_exactly('admin', 'student')
    end
  end
  describe '#update_results!' do
    let(:test_run) { create :test_run, status: :in_progress }
    let(:test_group) { create(:test_group) }
    let(:results) do
      JSON.parse({ status: :finished,
                   error: nil,
                   test_groups: [{
                     time: 10,
                     timeout: nil,
                     stderr: '',
                     malformed: '',
                     extra_info: { test_group_id: test_group.id },
                     tests: [{
                       name: :test1,
                       status: :pass,
                       marks_earned: 1,
                       marks_total: 1,
                       output: 'output',
                       time: 1
                     }, {
                       name: :test2,
                       status: :fail,
                       marks_earned: 0,
                       marks_total: 1,
                       output: 'failure',
                       time: nil
                     }]
                   }] }.to_json)
    end
    context 'there is a failure reported' do
      before { results['status'] = 'failed' }
      it 'should change the status to failure' do
        expect { test_run.update_results!(results) }.to change { test_run.status }.to('failed')
      end
    end
    context 'there is a success reported' do
      let(:test_group_result) { TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id) }
      it 'should update the status to completed' do
        expect { test_run.update_results!(results) }.to change { test_run.status }.to('complete')
      end
      context 'there is an error message' do
        before { results['error'] = 'error message' }
        it 'should update the problems' do
          expect { test_run.update_results!(results) }.to change { test_run.problems }.to('error message')
        end
      end
      it 'should create a test group result' do
        test_run.update_results!(results)
        expect(test_group_result).not_to be_nil
      end
      context 'setting the extra_info attribute' do
        context 'when both stderr and malformed are blank' do
          it 'should set extra_info to nil' do
            test_run.update_results!(results)
            expect(test_group_result.extra_info).to be_nil
          end
        end
        context 'when stderr is not nil' do
          it 'should set extra_info' do
            results['test_groups'].first['stderr'] = 'error'
            test_run.update_results!(results)
            msg = I18n.t('automated_tests.results.extra_stderr', extra: 'error')
            expect(test_group_result.extra_info).to eq msg
          end
        end
        context 'when malformed is not nil' do
          it 'should set extra_info' do
            results['test_groups'].first['malformed'] = 'error'
            test_run.update_results!(results)
            msg = I18n.t('automated_tests.results.extra_malformed', extra: 'error')
            expect(test_group_result.extra_info).to eq msg
          end
        end
        context 'when both are not nil' do
          it 'should set extra_info' do
            results['test_groups'].first['stderr'] = 'stderr error'
            results['test_groups'].first['malformed'] = 'malformed error'
            test_run.update_results!(results)
            msg = I18n.t('automated_tests.results.extra_stderr', extra: 'stderr error')
            msg += I18n.t('automated_tests.results.extra_malformed', extra: 'malformed error')
            expect(test_group_result.extra_info).to eq msg
          end
        end
      end
      context 'when the marks_total and marks_earned values are set' do
        it 'should set the marks_total to 2' do
          test_run.update_results!(results)
          expect(test_group_result.marks_total).to eq 2
        end
        it 'should set the marks_earned to 1' do
          test_run.update_results!(results)
          expect(test_group_result.marks_earned).to eq 1
        end
      end
      context 'when the marks_total and marks_earned values are not set' do
        before { results['test_groups'].first['tests'].each { |t| t['marks_earned'] = t['marks_total'] = nil } }
        it 'should set the marks_total to 0' do
          test_run.update_results!(results)
          expect(test_group_result.marks_total).to eq 0
        end
        it 'should set the marks_earned to 0' do
          test_run.update_results!(results)
          expect(test_group_result.marks_earned).to eq 0
        end
      end
      context 'when time is set' do
        it 'should set the time attribute' do
          test_run.update_results!(results)
          expect(test_group_result.time).to eq 10
        end
      end
      context 'when time is not set' do
        it 'should set the time attribute' do
          results['test_groups'].first['time'] = nil
          test_run.update_results!(results)
          expect(test_group_result.time).to eq 0
        end
      end
      context 'when tests are empty' do
        before { results['test_groups'].first['tests'] = [] }
        context 'when timeout is set' do
          before { results['test_groups'].first['timeout'] = 5 }
          it 'should set error_type to timeout' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to eq TestGroupResult::ERROR_TYPE[:timeout].to_s
          end
        end
        context 'when timeout is not set' do
          it 'should set error_type to no_result' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to eq TestGroupResult::ERROR_TYPE[:no_results].to_s
          end
        end
      end
      context 'when tests are not empty' do
        context 'when timeout is set' do
          before { results['test_groups'].first['timeout'] = 5 }
          it 'should set error_type to timeout' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to be_nil
          end
        end
        context 'when timeout is not set' do
          it 'should set error_type to no_result' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to be_nil
          end
        end
      end
      context 'when an error occurs' do
        before do
          allow_any_instance_of(TestGroupResult).to receive(:test_results).and_raise(StandardError, 'error msg')
          test_run.update_results!(results)
        end
        it 'should create a test group result' do
          expect(test_group_result).not_to be_nil
        end
        it 'should create a test group result with the error message as extra_info' do
          expect(test_group_result.extra_info).to eq 'error msg'
        end
        it 'should create a test group result with the marks_total as 0' do
          expect(test_group_result.marks_total).to eq 0
        end
        it 'should create a test group result with the marks_earned as 0' do
          expect(test_group_result.marks_earned).to eq 0
        end
        it 'should create a test group result with the error_type as test_error' do
          expect(test_group_result.error_type).to eq TestGroupResult::ERROR_TYPE[:test_error].to_s
        end
      end
      context 'creating test results' do
        it 'should create 2 test group results' do
          expect { test_run.update_results!(results) }.to change { TestResult.count }.from(0).to(2)
        end
        it 'should associate the test results with the test group result' do
          test_run.update_results!(results)
          expect(TestResult.where(test_group_result: test_group_result).count).to eq 2
        end
        it 'should create a test_result with correct info' do
          test_run.update_results!(results)
          expect(TestResult.where(results['test_groups'].first['tests'].first)).not_to be_nil
        end
        it 'should create the other test_result with correct info' do
          test_run.update_results!(results)
          expect(TestResult.where(results['test_groups'].first['tests'].second)).not_to be_nil
        end
        it 'should remove null values from the output' do
          results['test_groups'].first['tests'].first['output'] = "abc\x00de"
          test_run.update_results!(results)
          expect(TestResult.where(output: 'abc\u0000de')).not_to be_nil
        end
      end
    end
  end
end
