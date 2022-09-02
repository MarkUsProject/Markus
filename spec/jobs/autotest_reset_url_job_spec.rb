describe AutotestResetUrlJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:url) { 'http://example.com' }
  let(:course) { create :course }
  context 'when running as a background job' do
    let(:job_args) { [course, url, host_with_port] }
    include_examples 'background job'
  end

  context 'when running as a foreground job' do
    subject { AutotestResetUrlJob.perform_now(course, url, host_with_port) }
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
          create_list :assignment, 3, course: course,
                                      assignment_properties_attributes: { remote_autotest_settings_id: 1 }
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
          create_list :assignment, 3, course: course,
                                      assignment_properties_attributes: { remote_autotest_settings_id: 1 }
        end
        it 'should not reset the remote_autotest_settings_id for all assignments' do
          subject
          expect(course.assignments.pluck(:remote_autotest_settings_id).to_set).to contain_exactly(1)
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
            create_list :assignment, 3, course: course,
                                        assignment_properties_attributes: { remote_autotest_settings_id: 1,
                                                                            autotest_settings: '{}' }
          end
          it 'should update the remote_autotest_settings_id for all assignments' do
            expect(AutotestSpecsJob).to receive(:perform_now).exactly(3).times
            subject
          end
        end
        context 'when assignments exist for the course and some have autotest settings' do
          before do
            create_list :assignment, 2, course: course,
                                        assignment_properties_attributes: { remote_autotest_settings_id: 1,
                                                                            autotest_settings: '{}' }
            create :assignment, course: course
          end
          it 'should update the remote_autotest_settings_id for all assignments' do
            expect(AutotestSpecsJob).to receive(:perform_now).exactly(2).times
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
