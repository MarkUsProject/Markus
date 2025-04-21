describe AutotestResultsJob do
  let(:assignment) { create(:assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:test_runs) { create_list(:test_run, 3, grouping: grouping, status: :in_progress) }

  context 'when running as a background job' do
    let(:job_args) { [] }
    let(:job) { AutotestResultsJob.perform_later(*job_args) }

    context 'when there is no job currently in progress' do
      before { redis.del('autotest_results') }

      it_behaves_like 'background job'
      it 'sets the redis key' do
        job
        expect(redis.get('autotest_results')).not_to be_nil
      end
    end

    context 'when there is a job currently in progress' do
      before do
        redis.set('autotest_results', 1)
        clear_enqueued_jobs
        clear_performed_jobs
      end

      after do
        clear_enqueued_jobs
        clear_performed_jobs
        redis.del('autotest_results')
      end

      it 'does not enqueue a job' do
        expect { job }.not_to have_enqueued_job
      end
    end
  end

  describe '#perform' do
    subject { AutotestResultsJob.perform_now }

    before do
      redis.del('autotest_results')
      allow_any_instance_of(AutotestSetting).to(
        receive(:send_request!).and_return(OpenStruct.new(body: { api_key: 'someapikey' }.to_json))
      )
      course = create(:course)
      course.autotest_setting = create(:autotest_setting)
      course.save
      test_runs.each_with_index { |t, i| t.update!(autotest_test_id: i + 1) }
    end

    context 'when tests are set up for an assignment' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { remote_autotest_settings_id: 10 }) }
      let(:dummy_return) { Net::HTTPSuccess.new(1.0, '200', 'OK') }
      let(:body) { '{}' }

      before { allow(dummy_return).to receive(:body) { body } }

      context 'when sending the request to the autotester' do
        it 'sets headers the correct headers' do
          expect_any_instance_of(AutotestResultsJob).to receive(:send_request!) do |_job, net_obj|
            expect(net_obj['Api-Key']).to eq assignment.course.autotest_setting.api_key
            expect(net_obj['Content-Type']).to eq 'application/json'
            dummy_return
          end
          subject
        end

        it 'sends the request to the correct URL with the correct request data' do
          expect_any_instance_of(AutotestResultsJob).to receive(:send_request!) do |_job, net_obj, uri|
            expect(net_obj.instance_of?(Net::HTTP::Get)).to be true
            expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/tests/status"
            expect(JSON.parse(net_obj.body)['test_ids']).to contain_exactly(1, 2, 3)
            dummy_return
          end
          subject
        end

        it_behaves_like 'autotest jobs'
      end

      context 'when getting the statuses of the tests' do
        before { allow_any_instance_of(AutotestResultsJob).to receive(:statuses).and_return(status_return) }

        shared_examples 'rescheduling a job' do
          before { allow_any_instance_of(AutotestResultsJob).to receive(:results) }

          it 'should schedule another job in a minute' do
            expect(AutotestResultsJob).to receive(:set).with(wait: 5.seconds).once.and_call_original
            expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).once
            subject
          end
        end

        shared_examples 'getting results' do
          describe 'a successful request' do
            it 'should set headers' do
              allow_any_instance_of(TestRun).to receive(:update_results!)
              expect_any_instance_of(AutotestResultsJob).to receive(:send_request) do |_job, net_obj|
                expect(net_obj['Api-Key']).to eq assignment.course.autotest_setting.api_key
                expect(net_obj['Content-Type']).to eq 'application/json'
                dummy_return
              end
              subject
            end

            it 'should send an api request to the autotester' do
              allow_any_instance_of(TestRun).to receive(:update_results!)
              expect_any_instance_of(AutotestResultsJob).to receive(:send_request) do |_job, net_obj, uri|
                expect(net_obj.instance_of?(Net::HTTP::Get)).to be true
                expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/test/2"
                dummy_return
              end
              subject
            end

            it 'should call update_results! for the test_run' do
              allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
              expect_any_instance_of(TestRun).to receive(:update_results!).with({}) do |test_run|
                expect(test_run.autotest_test_id).to eq 2
              end
              subject
            end

            context 'when the result contains feedback file information' do
              let(:body) { { test_groups: [{ feedback: [{ id: 992 }, { id: 882 }] }] }.to_json }

              before do
                allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
              end

              it 'should add feedback content for all feedback files' do
                expect_any_instance_of(TestRun).to receive(:update_results!) do |_test_run, result|
                  expect(
                    result['test_groups'].flat_map { |h| h['feedback'].filter_map { |hh| hh['content'] } }.length
                  ).to eq 2
                end
                subject
              end
            end
          end

          describe 'an unsuccessful request' do
            let(:dummy_return) { Net::HTTPServerError.new(1.0, '500', 'Server Error') }

            before do
              allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
            end

            it 'should call failure for the test_run' do
              expect_any_instance_of(TestRun).to receive(:failure).with('{}') do |test_run|
                expect(test_run.autotest_test_id).to eq 2
              end
              subject
            end
          end
        end

        shared_examples 'web socket table update' do
          let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
          let(:test_run1) { create(:test_run, grouping: grouping, status: :in_progress) }
          let(:test_run2) { create(:student_test_run, grouping: grouping, status: :in_progress) }
          let(:test_run3) { create(:test_run, grouping: grouping, status: :in_progress) }
          let(:test_runs) { [test_run1, test_run2, test_run3] }
          let(:student) { grouping.inviter.user }
          let(:student2) { create(:student).user }
          before do
            allow_any_instance_of(TestRun).to receive(:update_results!)
            allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
          end

          context 'when getting results for a completed test' do
            it 'broadcasts a message to the user' do
              expect { AutotestResultsJob.perform_now }
                .to have_broadcasted_to(student).from_channel(TestRunsChannel)
                                                .with(status: 'completed', job_class: 'AutotestResultsJob')
            end

            it 'broadcasts exactly one message' do
              expect { AutotestResultsJob.perform_now }
                .to have_broadcasted_to(student).from_channel(TestRunsChannel).once
            end

            it "doesn't broadcast the message to other users" do
              expect { AutotestResultsJob.perform_now }
                .to have_broadcasted_to(student2).from_channel(TestRunsChannel).exactly 0
            end
          end

          context 'when a the test was batch run' do
            let(:test_run2) do
              create(:batch_test_run, grouping: grouping, role: grouping.inviter, status: :in_progress)
            end

            it 'broadcasts a message to the user' do
              expect { AutotestResultsJob.perform_now }
                .to have_broadcasted_to(student).from_channel(TestRunsChannel)
                                                .with(status: 'completed',
                                                      job_class: 'AutotestResultsJob',
                                                      assignment_ids: [grouping.assessment_id],
                                                      update_table: true)
            end
          end
        end

        shared_examples 'web sockets test in progress' do
          let(:grouping) { create(:grouping_with_inviter) }
          let(:test_run1) { create(:test_run, grouping: grouping, status: :in_progress) }
          let(:test_run2) { create(:student_test_run, grouping: grouping, status: :in_progress) }
          let(:test_run3) { create(:test_run, grouping: grouping, status: :in_progress) }
          let(:test_runs) { [test_run1, test_run2, test_run3] }
          let(:student) { grouping.inviter.user }
          it 'should not broadcast anything' do
            allow_any_instance_of(TestRun).to receive(:update_results!)
            allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
            expect { AutotestResultsJob.perform_now }
              .to have_broadcasted_to(student).from_channel(TestRunsChannel).exactly 0
          end
        end

        context 'when at least one of the statuses is "started"' do
          let(:status_return) { { 1 => 'finished', 2 => 'started', 3 => 'finished' } }

          it_behaves_like 'rescheduling a job'
          it_behaves_like 'web sockets test in progress'
        end

        context 'when at least one of the statuses is "queued"' do
          let(:status_return) { { 1 => 'finished', 2 => 'queued', 3 => 'finished' } }

          it_behaves_like 'rescheduling a job'
          it_behaves_like 'web sockets test in progress'
        end

        context 'when at least one of the statuses is "deferred"' do
          let(:status_return) { { 1 => 'finished', 2 => 'deferred', 3 => 'finished' } }

          it_behaves_like 'rescheduling a job'
          it_behaves_like 'web sockets test in progress'
        end

        context 'when at least one of the statuses is "finished"' do
          let(:status_return) { { 1 => 'started', 2 => 'finished', 3 => 'started' } }

          it_behaves_like 'getting results'
          it_behaves_like 'web socket table update'
        end

        context 'when at least one of the statuses is "failed"' do
          let(:status_return) { { 1 => 'started', 2 => 'failed', 3 => 'started' } }

          it_behaves_like 'getting results'
          it_behaves_like 'web socket table update'
        end

        context 'when at least one of the statuses is something else' do
          let(:status_return) { { 1 => 'started', 2 => 'something else', 3 => 'started' } }

          it 'should call failure for the test_run' do
            expect_any_instance_of(TestRun).to receive(:failure).with('something else') do |test_run|
              expect(test_run.autotest_test_id).to eq 2
            end
            subject
          end

          it_behaves_like 'web socket table update'
        end

        context 'when there is a test run with the same autotest_test_id in a different course' do
          let(:status_return) { { 1 => 'finished' } }
          let(:other_course) { create(:course, autotest_setting: create(:autotest_setting)) }
          let(:other_role) { create(:instructor, course: other_course) }
          let(:other_assignment) do
            create(:assignment,
                   assignment_properties_attributes: { remote_autotest_settings_id: 11 },
                   course: other_course)
          end
          let(:other_grouping) { create(:grouping, assignment: other_assignment) }
          let(:test_runs) { [] }
          let(:other_test_runs) do
            [
              create(:test_run, grouping: grouping, autotest_test_id: 1, status: :in_progress),
              create(:test_run, grouping: other_grouping, role: other_role,
                                autotest_test_id: 1, status: :in_progress)
            ]
          end

          before do
            grouping.course.autotest_setting = create(:autotest_setting)
            other_test_runs
          end

          it 'should get results for both test runs' do
            allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
            called_test_runs = []
            allow_any_instance_of(AutotestResultsJob).to receive(:results) do |_job, _assignment, test_run|
              called_test_runs << test_run
            end
            subject
            expect(called_test_runs.map(&:id)).to match_array(other_test_runs.map(&:id))
          end
        end
      end
    end

    context 'when tests are not set up' do
      it 'should try again with reduced retries' do
        expect { subject }.to raise_error(I18n.t('automated_tests.settings_not_setup'))
      end
    end
  end
end
