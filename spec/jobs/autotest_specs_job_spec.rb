describe AutotestSpecsJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:assignment) { create(:assignment) }
  let(:dummy_return) { OpenStruct.new(body: { 'settings_id' => 43 }.to_json) }

  context 'when running as a background job' do
    let(:job_args) { [host_with_port, assignment, {}] }

    it_behaves_like 'background job'
  end

  context 'when running as a foreground job' do
    before do
      allow_any_instance_of(AutotestSetting).to(
        receive(:send_request!).and_return(OpenStruct.new(body: { api_key: 'someapikey' }.to_json))
      )
      course = create(:course)
      course.autotest_setting = create(:autotest_setting)
      course.save
    end

    shared_examples 'autotest specs job' do
      it 'should set headers' do
        expect_any_instance_of(AutotestSpecsJob).to receive(:send_request!) do |_job, net_obj|
          expect(net_obj['Api-Key']).to eq assignment.course.autotest_setting.api_key
          expect(net_obj['Content-Type']).to eq 'application/json'
          dummy_return
        end
        subject
      end

      it 'should set the body of the request' do
        rel_url_root = Rails.configuration.relative_url_root
        file_url = "http://localhost:3000#{rel_url_root}/api/courses/#{assignment.course.id}/" \
                   "assignments/#{assignment.id}/test_files"
        expect_any_instance_of(AutotestSpecsJob).to receive(:send_request!) do |_job, net_obj|
          expect(JSON.parse(net_obj.body).symbolize_keys).to eq(settings: {},
                                                                file_url: file_url,
                                                                files: assignment.autotest_files)
          dummy_return
        end
        subject
      end

      it 'should update the remote_autotest_settings_id' do
        allow_any_instance_of(AutotestSpecsJob).to receive(:send_request!).and_return(dummy_return)
        subject
        expect(assignment.remote_autotest_settings_id).to eq 43
      end
    end

    describe '#perform' do
      subject { AutotestSpecsJob.perform_now(host_with_port, assignment, {}) }

      before do
        allow(File).to receive(:read).and_return("123456789\n")
      end

      context 'tests are set up for an assignment' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { remote_autotest_settings_id: 10 }) }

        it 'should send an api request to the autotester' do
          expect_any_instance_of(AutotestSpecsJob).to receive(:send_request!) do |_job, net_obj, uri|
            expect(net_obj.instance_of?(Net::HTTP::Put)).to be true
            expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10"
            dummy_return
          end
          subject
        end

        it_behaves_like 'autotest specs job'
        it_behaves_like 'autotest jobs'
      end

      context 'tests are not set up for an assignment' do
        it 'should send an api request to the autotester' do
          expect_any_instance_of(AutotestSpecsJob).to receive(:send_request!) do |_job, net_obj, uri|
            expect(net_obj.instance_of?(Net::HTTP::Post)).to be true
            expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings"
            dummy_return
          end
          subject
        end

        it_behaves_like 'autotest specs job'
      end
    end
  end
end
