describe AutotestResetUrlJob do
  include AutomatedTestsHelper
  let(:host_with_port) { 'http://localhost:3000' }
  let(:url) { 'http://example.com' }
  let(:course) { create(:course) }

  context 'when running as a background job' do
    let(:job_args) { [course, url, host_with_port] }

    it_behaves_like 'background job'
  end

  context 'when running as a foreground job' do
    subject { AutotestResetUrlJob.perform_now(course, url, host_with_port, refresh: refresh) }

    let(:refresh) { false }

    before do
      allow_any_instance_of(AutotestSetting).to receive(:register).and_return(1)
      allow_any_instance_of(AutotestSetting).to receive(:get_schema).and_return('{}')
      allow_any_instance_of(AutotestSetting).to receive(:update_settings)
    end

    context 'when no autotest setting already exists for that url' do
      it 'should create a new autotest setting' do
        expect { subject }.to(change { AutotestSetting.where(url: url).count }.from(0).to(1))
      end

      it 'should associate the new setting with the course' do
        subject
        expect(course.reload.autotest_setting.url).to eq url
      end

      context 'when assignments exist for the course' do
        before do
          3.times do |i|
            create(:assignment, course: course, assignment_properties_attributes: { remote_autotest_settings_id: i })
          end
        end

        it 'should reset the remote_autotest_settings_id for all assignments' do
          subject
          expect(course.assignments.pluck(:remote_autotest_settings_id).compact).to be_empty
        end
      end
    end

    context 'when an autotest setting exists for that url' do
      let(:old_url) { url }

      before { course.update! autotest_setting_id: create(:autotest_setting, url: old_url).id }

      it 'should not create a new autotest setting' do
        expect { subject }.not_to(change { AutotestSetting.where(url: url).count })
      end

      it 'should not change the association' do
        subject
        expect(course.reload.autotest_setting.url).to eq url
      end

      context 'when assignments exist for the course' do
        before do
          3.times do |i|
            create(:assignment, course: course, assignment_properties_attributes: { remote_autotest_settings_id: i })
          end
        end

        it 'should not reset the remote_autotest_settings_id for all assignments' do
          subject
          expect(course.assignments.pluck(:remote_autotest_settings_id).to_set).to contain_exactly(0, 1, 2)
        end
      end

      context 'when refresh is true' do
        let(:refresh) { true }

        it 'should call update_credentials' do
          expect_any_instance_of(AutotestResetUrlJob).to receive(:update_credentials)
          subject
        end

        context 'when assignments exist for the course and all have autotest settings' do
          before do
            allow_any_instance_of(AutotestResetUrlJob).to receive(:update_credentials)
            3.times do |i|
              create(:assignment, course: course, assignment_properties_attributes: { remote_autotest_settings_id: i,
                                                                                      autotest_settings: '{}' })
            end
          end

          it 'should update the remote_autotest_settings_id for all assignments' do
            expect(AutotestSpecsJob).to receive(:perform_now).exactly(3).times
            subject
          end

          it 'should updated call AutotestSpecsJob with the right arguments' do
            allow(AutotestSpecsJob).to receive(:perform_now) do |_url, assignment, test_specs|
              expect(test_specs).to eq autotest_settings_for(assignment)
            end
            subject
          end
        end

        context 'when assignments exist for the course and some have autotest settings' do
          before do
            allow_any_instance_of(AutotestResetUrlJob).to receive(:update_credentials)
            2.times do |i|
              create(:assignment, course: course, assignment_properties_attributes: { remote_autotest_settings_id: i,
                                                                                      autotest_settings: '{}' })
            end
            create(:assignment, course: course)
          end

          it 'should update the remote_autotest_settings_id for all assignments' do
            expect(AutotestSpecsJob).to receive(:perform_now).twice
            subject
          end
        end
      end

      context 'when the autotest setting is changed' do
        let(:old_url) { 'http://example.com/other' }

        it 'should associate the new setting with the course' do
          subject
          expect(course.reload.autotest_setting.url).to eq url
        end

        context 'when assignments exist for the course and all have autotest settings' do
          before do
            3.times do |i|
              create(:assignment, course: course, assignment_properties_attributes: { remote_autotest_settings_id: i,
                                                                                      autotest_settings: '{}' })
            end
          end

          it 'should update the remote_autotest_settings_id for all assignments' do
            expect(AutotestSpecsJob).to receive(:perform_now).exactly(3).times
            subject
          end
        end

        context 'when assignments exist for the course and some have autotest settings' do
          before do
            2.times do |i|
              create(:assignment, course: course, assignment_properties_attributes: { remote_autotest_settings_id: i,
                                                                                      autotest_settings: '{}' })
            end
            create(:assignment, course: course)
          end

          it 'should update the remote_autotest_settings_id for all assignments' do
            expect(AutotestSpecsJob).to receive(:perform_now).twice
            subject
          end
        end

        context 'when the autotest setting is changed to a blank value' do
          let(:url) { '' }
          let(:old_url) { 'http://example.com' }

          it 'should associate the course with no autotest settings' do
            subject
            expect(course.reload.autotest_setting).to be_nil
          end

          it 'should reset the remote_autotest_settings_id for all assignments' do
            subject
            expect(course.assignments.pluck(:remote_autotest_settings_id).compact).to be_empty
          end
        end
      end
    end
  end
end
